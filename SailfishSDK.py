from contextlib import ExitStack
from datetime import datetime
import filecmp
import fileinput
import os.path
from pathlib import Path
from robot.errors import ExecutionFailed
from robot.libraries.BuiltIn import BuiltIn, RobotNotRunningError
from robot.libraries.OperatingSystem import OperatingSystem
from robot.libraries.Process import Process
from robot.utils import get_link_path, is_truthy
from robot.utils.dotdict import DotDict
from robot.variables import Variables
import shlex
import shutil
import sys
import tempfile

# TODO Python 3.8: Use shlex.join
def shlex_join(args):
    return ' '.join(shlex.quote(arg) for arg in args)

class ConfigurationError(RuntimeError):
    ROBOT_SUPPRESS_NAME = True
    # FIXME: This does not work
    ROBOT_EXIT_ON_FAILURE = True

class _Attachment:
    def __init__(self, base_name):
        name = Path(base_name)
        name = Path(name.stem + '.' + self._make_timestamp() + name.suffix)
        self._path = Path(self._attachments_dir, name)
        self._path.parent.mkdir(parents=True, exist_ok=True)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        if self.path.exists():
            self._attach()

    @property
    def path(self):
        return self._path

    def _attach(self):
        link = get_link_path(self._path, self._log_dir)
        BuiltIn().log('Attachment: <a href="{}">{}</a>'.format(link, self._path.name), html=True)

    @property
    def _attachments_dir(self):
        variables = BuiltIn().get_variables()
        suite_name = variables['${SUITE_NAME}']
        return Path(self._log_dir, 'attachments', suite_name)

    @property
    def _log_dir(self):
        variables = BuiltIn().get_variables()
        out_dir = variables['${OUTPUTDIR}']
        log = variables['${LOGFILE}']
        log_dir = Path(log).parent if log != 'NONE' else Path.cwd()
        return Path(out_dir, log_dir)

    def _make_timestamp(self):
        return datetime.now().strftime('%y%m%d-%H%M%S-%f')

class _Variables:

    def get_variables(self):
        config = self._load_config()
        variables = dict(config)

        os_variant = DotDict(
                pretty=config.OS_VARIANT,
                nospace=config.OS_VARIANT.replace(' ', ''),
                underscore=config.OS_VARIANT.replace(' ', '_'))
        variables['OS_VARIANT'] = os_variant

        sdk_variant = DotDict(
                pretty=config.SDK_VARIANT,
                nospace=config.SDK_VARIANT.replace(' ', ''),
                underscore=config.SDK_VARIANT.replace(' ', '_'))
        variables['SDK_VARIANT'] = sdk_variant

        sdk_install_dir = config.SDK_INSTALL_DIR
        sdk_install_dir = os.path.expanduser(sdk_install_dir)
        variables['SDK_INSTALL_DIR'] = sdk_install_dir

        device_is_emulator = config.DEVICE_TYPE == 'emulator'

        device_os_version = config.DEVICE_OS_VERSION
        os_version = config.OS_VERSION.get(device_os_version, device_os_version)
        if config.DEVICE_OS_VERSION == 'ea':
            os_version_suffix = 'EA'
        else:
            os_version_suffix = ''

        build_target = (os_variant.nospace + '-' + os_version + os_version_suffix + '-'
                + config.DEVICE_ARCH)

        if device_is_emulator:
            # FIXME: Emulator names do not match package names
            # FIXME: There are no EA emulators
            #name = os_variant.nospace + '-' + os_version + os_version_suffix
            device_name = os_variant.pretty + ' Emulator ' + os_version + os_version_suffix
        else:
            device_name = build_target

        device = DotDict(
                name=device_name,
                is_emulator=device_is_emulator,
                arch=config.DEVICE_ARCH,
                build_target=build_target,
                user=config.DEVICE_USER)
        variables['DEVICE'] = device

        # Encourage use of DEVICE.* instead
        del variables['DEVICE_TYPE']
        del variables['DEVICE_ARCH']
        del variables['DEVICE_OS_VERSION']
        del variables['DEVICE_USER']

        variables['SDK_CONFIG_DIR'] = os.path.expanduser('~/.config/' + sdk_variant.nospace)
        variables['SDK_MAINTENANCE_TOOL'] = sdk_install_dir + '/SDKMaintenanceTool'
        variables['SFDK'] = sdk_install_dir + '/bin/sfdk'

        return variables

    def _load_config(self):
        """Load config.py as a variable file in a way that the individual
        variables can be overriden on command line as if it was loaded
        explicitly as a variables file.
        """

        source_dir = os.path.dirname(os.path.abspath(__file__))

        # Config file is meant to live in the output directory...
        config_file = os.path.abspath('config.py')
        if not os.path.exists(config_file):
            # ...but look also into the sources to allow RED to do its job
            config_file = os.path.join(source_dir, 'config.py')

        if not os.path.exists(config_file):
            configure = os.path.join(source_dir, 'configure')
            configure = os.path.relpath(configure)
            raise ConfigurationError("Configuration file not found. Forgot to run '{}'?"
                    .format(configure))

        config = Variables()
        config.set_from_file(config_file)

        try:
            global_variables = BuiltIn().get_variables()
            for name in config.as_dict():
                if name in global_variables:
                    config[name] = global_variables[name]
        except RobotNotRunningError:
            # Use the defaults when the IDE queries variables
            pass

        return DotDict(config.as_dict(decoration=False))


class SailfishSDK(_Variables):
    ROBOT_LIBRARY_VERSION = 1.0
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'

    def maybe_install_sdk(self, vbox_engine_memory_size_mb=None):
        variables = BuiltIn().get_variables()

        sdk_install_dir = variables['${SDK_INSTALL_DIR}']

        use_existing_sdk_installation = variables['${USE_EXISTING_SDK_INSTALLATION}']
        if use_existing_sdk_installation:
            OperatingSystem().directory_should_exist(sdk_install_dir)
            # Ensure we always return a valid result object
            return Process().run_process('true')

        try:
            OperatingSystem().directory_should_not_exist(sdk_install_dir)
        except:
            # Ensure maybe_uninstall_sdk will not destroy existing installation
            BuiltIn().set_global_variable('${USE_EXISTING_SDK_INSTALLATION}', True)
            raise

        command = variables['${INSTALLER}']
        build_engine_type = variables['${BUILD_ENGINE_TYPE}']
        args = variables['@{INSTALLER_ARGS}'] + ['--verbose', 'non-interactive=1',
                'accept-licenses=1', 'build-engine-type=' + build_engine_type]
        result = self._run_process(command, *args, token='installer')

        if build_engine_type == 'vbox' and vbox_engine_memory_size_mb:
            args = ['engine', 'set', 'vm.memorySize=' + vbox_engine_memory_size_mb]
            result = self.run_sfdk(*args)

        if variables['${DO_SSU_REGISTER}']:
            credentials_file = variables['${SSU_CREDENTIALS_FILE}']
            args = ['engine', 'exec', 'bash', '-c',
                    'IFS=: read -r ssu_user ssu_pass \
                        && sdk-manage register-all --force \
                            --user "${ssu_user}" --password "${ssu_pass}" \
                        && sdk-manage refresh-all']
            result = self.run_sfdk(*args, tty=True, redirection='<'+credentials_file)
            args = ['emulator', 'exec', 'bash', '-c',
                    'IFS=: read -r ssu_user ssu_pass \
                        && sudo /usr/libexec/sdk-setup/sdk-register \
                            -u "${ssu_user}" -p "${ssu_pass}"']
            result = self.run_sfdk(*args, tty=True, redirection='<'+credentials_file)

        # We just need to return some valid result object
        return result

    def maybe_uninstall_sdk(self):
        variables = BuiltIn().get_variables()
        use_existing_sdk_installation = variables['${USE_EXISTING_SDK_INSTALLATION}']

        if use_existing_sdk_installation:
            # Ensure we always return a valid result object
            return Process().run_process('true')

        return self._run_sdk_maintenance_tool(mode='uninstall')

    def manage_sdk_packages(self, action, *packages):
        if action != 'add' and action != 'remove':
            raise ValueError("Not a recognized action: '{}'".format(action))
        action_arg = action + '-packages=' + ','.join(packages)
        return self._run_sdk_maintenance_tool(action_arg, mode='manage-packages')

    def run_sfdk(self, *args, **configuration):
        variables = BuiltIn().get_variables()
        command = variables['${SFDK}']
        return self._run_process(command, *args, token='sfdk', **configuration)

    def vboxsf_safe_remove_directory(self, path, recursive=False):
        """Same as BuiltIn.remove_directory but executes inside build engine to
        prevent breaking vboxsf.

        Removing and recreating a directory on host quickly may break vboxsf in
        a way that 'stat' still recognizes it as a directory but other
        operations like 'ls' or 'cd' fail with 'Not a directory' error.
        """
        args = ["engine", "exec", "rm", "--force"]
        if recursive:
            args += ["--recursive"]
        args += [path]
        return self.run_sfdk(*args)

    def remove_directory_from_device(self, path, recursive=False):
        args = ["device", "exec", "rm", "--force"]
        if recursive:
            args += ["--recursive"]
        args += [path]
        return self.run_sfdk(*args)

    def write_random_content(self, path, approx_size):
        with open(path, 'w') as f:
            f.write(os.urandom(int(approx_size / 2)).hex('\n', 1024))

    def files_should_be_equal(self, path1, path2):
        if not filecmp.cmp(path1, path2, shallow=False):
            raise AssertionError('Files differ')

    def append_to_line_in_file(self, file, pattern, addition):
        """ Add text to lines matching a pattern
        """
        for line in fileinput.input(file, inplace=1):
            if pattern in line:
                line = line.rstrip() + addition + '\n'
            sys.stdout.write(line)

    def _run_sdk_maintenance_tool(self, *extra_args, mode='manage-packages'):
        variables = BuiltIn().get_variables()
        command = variables['${SDK_MAINTENANCE_TOOL}']

        args = ['--verbose', 'non-interactive=1', '--platform', 'minimal',
                'accept-licenses=1']

        if mode == 'uninstall':
            pass
        elif mode == 'manage-packages':
            args.append('--manage-packages')
        elif mode == 'update':
            args.append('--updater')
        else:
            raise ValueError("Not a recognized mode: '{}'.".format(mode))

        args.extend(extra_args)

        return self._run_process(command, *args,
                token='sdk-maintenance-tool')

    def _run_process(self, command, *arguments, **configuration):

        expected_rc = int(configuration.pop('expected_rc', 0))
        token = configuration.pop('token', 'process')
        merged_output = is_truthy(configuration.pop('merged_output', True))
        input = configuration.pop('input', None)
        if input and not isinstance(input, bytes):
            input = input.encode()
        tty = is_truthy(configuration.pop('tty', False))
        redirection = configuration.pop('redirection', None)

        # For compatibility with Process.run_process()
        timeout = configuration.pop('timeout', None)
        on_timeout = configuration.pop('on_timeout', 'terminate')

        if redirection and not tty:
            raise ValueError('Cannot use "redirection" without "tty"')

        with ExitStack() as stack:
            if merged_output:
                stdout = stack.enter_context(_Attachment(token + '-output.txt')).path
                stderr = 'STDOUT'
            else:
                stdout = stack.enter_context(_Attachment(token + '-stdout.txt')).path
                stderr = stack.enter_context(_Attachment(token + '-stderr.txt')).path

            if tty:
                joined = shlex_join((command,) + arguments)
                if redirection:
                    joined += ' ' + redirection
                command = 'script'
                arguments = list()
                arguments += ['--return']
                arguments += ['--quiet']
                arguments += ['--echo', 'never', '--log-out', '/dev/null']
                arguments += ['--command', joined]

            process = Process()
            process_object = process.start_process(command, *arguments, **configuration,
                    stdout=str(stdout), stderr=str(stderr), stdin='PIPE')

            if input:
                process_object.stdin.write(input)
                process_object.stdin.close()

            result = process.wait_for_process(process_object, timeout, on_timeout)

            if result.rc != expected_rc:
                raise AssertionError('Process exited with unexpected code {}'.format(result.rc))
            return result
