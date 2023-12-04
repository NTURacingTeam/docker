#!/usr/bin/python3
# PYTHON_ARGCOMPLETE_OK

from abc import ABC, abstractmethod, abstractproperty
import argcomplete
import argparse
from datetime import datetime, timedelta, timezone
import docker
from functools import lru_cache
import os
import prettytable
import re
import subprocess
import sys
import tempfile
import yaml


# command abstract class #######################################################
class Command(ABC):
    """
    Abstract class for commands
    """

    @abstractproperty
    def name(self) -> str:
        """
        Command name

        Returns
        -------
        str: command name
        """
        pass

    @abstractproperty
    def help(self) -> str:
        """
        Help message

        Returns
        -------
        str: help message
        """
        pass

    @abstractmethod
    def build_parser(self, parser: argparse.ArgumentParser) -> None:
        """
        Build parser

        Parameters
        ----------
        parser (argparse.ArgumentParser): parser to build
        """
        pass

    @abstractmethod
    def execute(self, args: argparse.Namespace) -> None:
        """
        Execute command

        Parameters
        ----------
        args (argparse.Namespace): arguments
        """
        pass

    def print_help(self):
        """
        Print help message
        """
        parser = argparse.ArgumentParser(prog=" ".join(sys.argv),
                                         description=self.help)
        self.build_parser(parser)
        parser.print_help()


class MetaCommand(Command):
    """
    Abstract class for meta commands
    """

    @property
    def subcommands(self) -> list[Command]:
        """
        Subcommands

        Returns
        -------
        list: list of subcommands
        """
        return []

    def build_meta_parser(self, parser: argparse.ArgumentParser) -> None:
        """
        Build parser for meta command. Default behavior is to do nothing.

        Parameters
        ----------
        parser (argparse.ArgumentParser): parser to build
        """
        pass

    def execute_meta(self, args: argparse.Namespace) -> None:
        """
        Execute meta command, called when no subcommand is specified. Default
        behavior is to print help message.

        Parameters
        ----------
        args (argparse.Namespace): arguments
        """
        self.print_help()

    def build_parser(self, parser):
        self.build_meta_parser(parser)
        subparsers = parser.add_subparsers(dest="subcommand_" + self.name,
                                           title="commands",
                                           metavar="COMMAND")
        for subcommand in self.subcommands:
            subparser = subparsers.add_parser(subcommand.name,
                                              description=subcommand.help,
                                              help=subcommand.help)
            subcommand.build_parser(subparser)

    def execute(self, args):
        subcommand = getattr(args, "subcommand_" + self.name)
        if subcommand:
            for command in self.subcommands:
                if subcommand == command.name:
                    command.execute(args)
                    break
        else:
            self.execute_meta(args)


class Application(Command):
    """
    Class for applications
    """

    @abstractproperty
    def version(self) -> str:
        """
        Application version

        Returns
        -------
        str: application version
        """
        return "unknown"

    def __init__(self):
        """
        Constructor
        """
        parser = argparse.ArgumentParser(prog=self.name,
                                         description=self.help)
        parser.add_argument("-v",
                            "--version",
                            action="version",
                            version="%(prog)s " + self.version)
        self.build_parser(parser)
        # enable autocomplete
        argcomplete.autocomplete(parser)
        args = parser.parse_args()
        self.execute(args)


# classes ######################################################################
class Container:
    """
    Class for storing docker containers information
    """

    docker_container = None
    name = None
    image = None
    status = None
    created = None
    started = None
    exited = None

    def from_docker_container(
            self,
            container: docker.models.containers.Container) -> "Container":
        """
        Initialize from docker container

        Parameters
        ----------
        container (docker.models.containers.Container): docker container
        """
        self.docker_container = container
        self.name = container.name
        self.image = container.image.attrs["RepoTags"][0]
        self.status = container.status

        # format: 2000-01-01T00:00:00.000000000+00:00, remove nanoseconds
        self.created = datetime.strptime(
            re.sub(r"\.\d+", "", container.attrs["Created"]),
            "%Y-%m-%dT%H:%M:%S%z")

        if self.status == "running":
            self.started = datetime.strptime(
                re.sub(r"\.\d+", "", container.attrs["State"]["StartedAt"]),
                "%Y-%m-%dT%H:%M:%S%z")
        elif self.status == "exited":
            self.exited = datetime.strptime(
                re.sub(r"\.\d+", "", container.attrs["State"]["FinishedAt"]),
                "%Y-%m-%dT%H:%M:%S%z")

        return self

    def to_str_array(self) -> list[str]:
        """
        Convert to string array in [name, image, created, status] format
        like "docker ps" command

        Returns
        -------
        list: string array
        """
        if not self.name:
            raise ValueError("container is not initialized")

        created = timedelta_to_human(
            datetime.now(timezone.utc) - self.created) + " ago"

        if self.status == "running":
            status = f"Up {timedelta_to_human(datetime.now(timezone.utc) - self.started)}"
        elif self.status == "exited":
            status = f"Exited {timedelta_to_human(datetime.now(timezone.utc) - self.exited)}"
        else:
            status = self.status

        return [self.name, self.image, created, status]


class Image:
    """
    Class for storing docker images information
    """

    docker_image = None
    name = None
    tag = None
    created = None
    size = None

    def from_docker_image(self, image: docker.models.images.Image) -> "Image":
        """
        Initialize from docker image

        Parameters
        ----------
        image (docker.models.images.Image): docker image
        """
        self.docker_image = image
        self.name = image.attrs["RepoTags"][0].split(":")[0]
        self.tag = image.attrs["RepoTags"][0].split(":")[1]

        # format: 2000-01-01T00:00:00.000000000+00:00, remove nanoseconds
        self.created = datetime.strptime(
            re.sub(r"\.\d+", "", image.attrs["Created"]),
            "%Y-%m-%dT%H:%M:%S%z")

        self.size = image.attrs["Size"]

        return self

    def from_name_tag(self, name: str, tag: str) -> "Image":
        """
        Initialize from name and tag

        Parameters
        ----------
        name (str): image name
        tag (str): image tag
        """
        self.name = name
        self.tag = tag

        return self

    def to_str_array(self) -> list[str]:
        """
        Convert to string array in [name, tag, created, size] format like
        "docker images" command

        Returns
        -------
        list: string array
        """
        if not self.name:
            raise ValueError("image is not initialized")

        ret = [self.name, self.tag]

        if self.created:
            ret.append(
                timedelta_to_human(datetime.now(timezone.utc) - self.created) +
                " ago")
        else:
            ret.append("N/A")

        if self.size:
            ret.append(bytes_to_human(self.size))
        else:
            ret.append("N/A")

        return ret

    def __eq__(self, other: "Image") -> bool:
        return self.name == other.name and self.tag == other.tag


# constants ####################################################################
NTURT_DOCKER_DIR = os.path.dirname(os.path.realpath(__file__))
DOCKERFILE_DIR = os.path.join(NTURT_DOCKER_DIR, "Dockerfile")
DOCKER_COMPOSE_DIR = os.path.join(NTURT_DOCKER_DIR, "docker-compose")
PACKAGE_DIR = os.path.join(NTURT_DOCKER_DIR, "packages")

DOCKER_CLIENT = docker.from_env()

ROOT_COMPOSE_FILES = ["rpi"]

IMAGE_ENTRY = "nturacing"
AVAILABLE_IMAGES = ["nturt_ros"]


# helper functions #############################################################
def timedelta_to_human(time_delta: timedelta) -> str:
    """
    Convert timedelta to human readable format

    Parameters
    ----------
    time_delta (datetime): timedelta

    Returns
    -------
    str: human readable format
    """
    if time_delta.days > 0:
        if time_delta.days >= 365:
            return f"{time_delta.days // 365} years"
        elif time_delta.days >= 30:
            return f"{time_delta.days // 30} months"
        elif time_delta.days >= 7:
            return f"{time_delta.days // 7} weeks"
        else:
            return f"{time_delta.days} days"
    elif time_delta.seconds >= 3600:
        return f"{time_delta.seconds // 3600} hours"
    elif time_delta.seconds >= 60:
        return f"{time_delta.seconds // 60} minutes"
    else:
        return f"{time_delta.seconds} seconds"


def bytes_to_human(size: int) -> str:
    """
    Convert bytes to human readable format

    Parameters
    ----------
    size (int): size in bytes

    Returns
    -------
    str: human readable format
    """
    power_labels = {0: "B", 1: "KB", 2: "MB", 3: "GB", 4: "TB"}

    power = 1000  # same as docker
    n = 0
    while size >= power:
        size /= power
        n += 1
    return f"{size:.2f}{power_labels[n]}"


@lru_cache(maxsize=1)
def list_sys_containers() -> list[Container]:
    """
    List system containers

    Returns
    -------
    list: list of system containers
    """
    ret = []
    for container in DOCKER_CLIENT.containers.list(all=True):
        ret.append(Container().from_docker_container(container))

    return ret


@lru_cache(maxsize=1)
def list_sys_images() -> list[Image]:
    """
    List system images, ignores images without tags

    Returns
    -------
    list: list of system images
    """
    ret = []
    for image in DOCKER_CLIENT.images.list():
        if image.attrs["RepoTags"]:
            ret.append(Image().from_docker_image(image))

    return ret


@lru_cache(maxsize=1)
def list_nturt_compose_files() -> list[str]:
    """
    List nturt docker-compose files

    Returns
    -------
    list: list of nturt docker-compose files
    """

    return os.listdir(DOCKER_COMPOSE_DIR)


def list_nturt_images(image_names: list[str] | None = None) -> list[Image]:
    """
    List nturt images, add created and size information if the image is
    available in system

    Parameters
    ----------
    image_names (list): list of image names, None to list all images

    Returns
    -------
    list: list of nturt images
    """
    sys_images = list_sys_images()

    ret = []
    if not image_names:
        image_names = AVAILABLE_IMAGES

    for name in image_names:
        image_dir = os.path.join(DOCKERFILE_DIR, name)
        for target in os.listdir(image_dir):
            target_dir = os.path.join(image_dir, target)
            for distro in os.listdir(target_dir):
                image = Image().from_name_tag(IMAGE_ENTRY + "/" + name,
                                              target + "-" + distro)
                if image in sys_images:
                    matched = sys_images[sys_images.index(image)]
                    image.created = matched.created
                    image.size = matched.size
                ret.append(image)
    return ret


# commands #####################################################################
# contianer commands ###########################################################
class NturtDockerContainerCreate(Command):
    """
    Command to create containers
    """

    @property
    def name(self):
        return "create"

    @property
    def help(self):
        return "create containers"

    def build_parser(self, parser):
        parser.add_argument("name",
                            help="name of the container to create",
                            metavar="NAME")
        parser.add_argument("image",
                            help="image to use",
                            metavar="IMAGE",
                            choices=[
                                f"{image.name}:{image.tag}"
                                for image in list_nturt_images()
                            ])
        parser.add_argument("mode",
                            help="mode of the container to create",
                            metavar="MODE",
                            choices=list_nturt_compose_files())

    def execute(self, args):
        compose_file = yaml.load(open(
            os.path.join(DOCKER_COMPOSE_DIR, args.mode, "docker-compose.yaml"),
            "r"),
                                 Loader=yaml.FullLoader)
        compose_file["services"]["container"]["image"] = args.image
        compose_file["services"]["container"]["hostname"] = args.image.split(
            ":")[1]
        compose_file["services"]["container"]["container_name"] = args.name

        if args.mode in ROOT_COMPOSE_FILES:
            compose_file["services"]["container"]["volumes"][
                -1] = os.path.join(PACKAGE_DIR, args.name) + ":/root/ws/src"
        else:
            compose_file["services"][
                "container"]["volumes"][-1] = os.path.join(
                    PACKAGE_DIR, args.name) + ":/home/docker/ws/src"

        if not os.path.exists(os.path.join(PACKAGE_DIR, args.name)):
            os.makedirs(os.path.join(PACKAGE_DIR, args.name))

        # create a temporary directory to store compose file
        with tempfile.TemporaryDirectory() as tmp_dir:
            with open(os.path.join(tmp_dir, "docker-compose.yaml"), "w") as f:
                yaml.dump(compose_file, f)
            subprocess.run(["docker", "compose", "up", "-d"], cwd=tmp_dir)


class NturtDockerContainerList(Command):
    """
    Command to list containers
    """

    HEADER = ["name", "image", "created", "status"]

    @property
    def name(self):
        return "list"

    @property
    def help(self):
        return "list containers"

    def build_parser(self, parser):
        pass

    def execute(self, args):
        table = prettytable.PrettyTable()
        table.field_names = self.HEADER

        contains = list_sys_containers()
        for container in contains:
            table.add_row(container.to_str_array())
        print(table)


class NturtDockerContainerRemove(Command):
    """
    Command to remove containers
    """

    @property
    def name(self):
        return "remove"

    @property
    def help(self):
        return "remove containers"

    def build_parser(self, parser):
        containers = list_sys_containers()
        parser.add_argument(
            "containers",
            help="containers to remove",
            metavar="CONTAINERS",
            choices=[container.name for container in containers],
            nargs="+")
        parser.add_argument(
            "-f",
            "--force",
            help="force remove containers even if it's running",
            action="store_true")

    def execute(self, args):
        if not args.force:
            for container in args.containers:
                if DOCKER_CLIENT.containers.get(container).status == "running":
                    print(f"ERROR: container {container} is running")
                    exit(1)
        for container in args.containers:
            print(f"Removing container {container}...")
            DOCKER_CLIENT.containers.get(container).remove(force=args.force)


class NturtDockerContainerShell(Command):
    """
    Command to attach shell into container
    """

    @property
    def name(self):
        return "shell"

    @property
    def help(self):
        return "attach shell into container"

    def build_parser(self, parser):
        containers = list_sys_containers()
        parser.add_argument(
            "container",
            help="container to shell into",
            metavar="CONTAINER",
            choices=[container.name for container in containers])
        parser.add_argument("-s",
                            "--shell",
                            help="shell to use, defualt to bash",
                            default="bash")

    def execute(self, args):
        container = DOCKER_CLIENT.containers.get(args.container)
        if container.status != "running":
            print("Container is not running, starting it...")
            container.start()
        subprocess.run(["docker", "exec", "-it", args.container, args.shell])


class NturtDockerContainerStart(Command):
    """
    Command to start containers
    """

    @property
    def name(self):
        return "start"

    @property
    def help(self):
        return "start containers"

    def build_parser(self, parser):
        containers = list_sys_containers()
        parser.add_argument("containers",
                            help="container to start",
                            metavar="CONTAINERS",
                            choices=[
                                container.name for container in containers
                                if container.status == "exited"
                            ],
                            nargs="+")

    def execute(self, args):
        for container in args.containers:
            print(f"Starting container {container}...")
            DOCKER_CLIENT.containers.get(container).start()


class NturtDockerContainerStop(Command):
    """
    Command to stop containers
    """

    @property
    def name(self):
        return "stop"

    @property
    def help(self):
        return "stop containers"

    def build_parser(self, parser):
        containers = list_sys_containers()
        parser.add_argument("containers",
                            help="container to shell into",
                            metavar="CONTAINERs",
                            choices=[
                                container.name for container in containers
                                if container.status == "running"
                            ],
                            nargs="+")

    def execute(self, args):
        for container in args.containers:
            print(f"Stopping container {container}...")
            DOCKER_CLIENT.containers.get(container).stop()


class NturtDockerContainer(MetaCommand):
    """
    Meta command for container related sub-commands
    """

    @property
    def name(self):
        return "container"

    @property
    def help(self):
        return "Various container related sub-commands"

    @property
    def subcommands(self):
        return [
            NturtDockerContainerCreate(),
            NturtDockerContainerList(),
            NturtDockerContainerRemove(),
            NturtDockerContainerShell(),
            NturtDockerContainerStart(),
            NturtDockerContainerStop()
        ]


# image commands ###############################################################
class NturtDockerImageBuild(Command):
    """
    Command to build nturt images
    """

    @property
    def name(self):
        return "build"

    @property
    def help(self):
        return "build nturt images natively"

    def build_parser(self, parser):
        images = list_nturt_images()
        parser.add_argument(
            "image",
            help="image to build",
            metavar="IMAGE",
            choices=[f"{image.name}:{image.tag}" for image in images])
        parser.add_argument(
            "--cache",
            help="use cache when building image, default to not use cache",
            action="store_true")
        parser.add_argument(
            "-f",
            "--force",
            help="force build if image already exists and remove it",
            action="store_true")
        parser.add_argument(
            "--not-pull",
            help=
            "do not attempt to pull new base image if any, default to attempt to pull new base image",
            action="store_true")

    def execute(self, args):
        for image in list_sys_images():
            if image.name == args.image.split(
                    ":")[0] and image.tag == args.image.split(":")[1]:
                if args.force:
                    DOCKER_CLIENT.images.remove(
                        image=f"{image.name}:{image.tag}", force=True)
                else:
                    print(
                        f"ERROR: image {image.name}:{image.tag} already exists"
                    )
                    exit(1)

        cmd = ["docker", "build"]

        if not args.cache:
            cmd.append("--no-cache")
        if not args.not_pull:
            cmd.append("--pull")

        cmd.extend(["--tag", args.image, "."])

        entry_name, tag = args.image.split(":")
        _, name = entry_name.split("/")
        target, distro = tag.split("-")

        image_dir = os.path.join(DOCKERFILE_DIR, name, target, distro)
        subprocess.run(cmd, cwd=image_dir)


class NturtDockerImageList(Command):
    """
    Command to list nturt images
    """

    HEADER = ["name", "tag", "created", "size"]

    @property
    def name(self):
        return "list"

    @property
    def help(self):
        return "list availiable nturt images"

    def build_parser(self, parser):
        murex_group = parser.add_mutually_exclusive_group()
        murex_group.add_argument("-i",
                                 "--images",
                                 help="list distros of specified image",
                                 metavar="IMAGES",
                                 choices=AVAILABLE_IMAGES,
                                 nargs="+")
        murex_group.add_argument("-s",
                                 "--system",
                                 help="list system images",
                                 action="store_true")

    def execute(self, args):
        table = prettytable.PrettyTable()
        table.field_names = self.HEADER

        sys_images = list_sys_images()

        # list system images
        if args.system:
            for image in sys_images:
                table.add_row(image.to_str_array())
            print(table)
            exit(0)

        if args.images:
            image_names = args.images
        else:
            image_names = AVAILABLE_IMAGES

        nturt_images = list_nturt_images(image_names)

        # list nturt images
        for image in nturt_images:
            table.add_row(image.to_str_array())
        print(table)


class NturtDockerImageRemove(Command):
    """
    Command to remove nturt images
    """

    @property
    def name(self):
        return "remove"

    @property
    def help(self):
        return "remove nturt images"

    def build_parser(self, parser):
        images = list_nturt_images()
        parser.add_argument(
            "images",
            help="images to remove",
            metavar="IMAGES",
            choices=[f"{image.name}:{image.tag}" for image in images],
            nargs="+")

    def execute(self, args):
        for image in args.images:
            DOCKER_CLIENT.images.remove(image=image, force=True)


class NturtDockerImage(MetaCommand):
    """
    Meta command for image related sub-commands
    """

    @property
    def name(self):
        return "image"

    @property
    def help(self):
        return "Various image related sub-commands"

    @property
    def subcommands(self):
        return [NturtDockerImageBuild(), NturtDockerImageList()]


# pwd commands #################################################################
class NturtDockerPWD(Command):
    """
    Command to print directory to nturt docker
    """

    @property
    def name(self):
        return "pwd"

    @property
    def help(self):
        return "print directory to nturt docker"

    def build_parser(self, parser):
        mutex_group = parser.add_mutually_exclusive_group()
        mutex_group.add_argument("-c",
                                 "--compose",
                                 help="directory to docker-compose",
                                 action="store_true")
        mutex_group.add_argument("-d",
                                 "--dockerfile",
                                 help="directory to dockerfile",
                                 action="store_true")
        mutex_group.add_argument("-p",
                                 "--package",
                                 help="directory to container package mount",
                                 action="store_true")

    def execute(self, args):
        if args.compose:
            print(DOCKER_COMPOSE_DIR)
        elif args.dockerfile:
            print(DOCKERFILE_DIR)
        elif args.package:
            print(PACKAGE_DIR)
        else:
            print(NTURT_DOCKER_DIR)


# application ##################################################################
class NturtDocker(Application, MetaCommand):
    """
    Main application
    """

    @property
    def name(self):
        return "nturt_docker"

    @property
    def help(self):
        return "nturt docker utilities"

    @property
    def version(self):
        return "0.0.0"

    @property
    def subcommands(self):
        return [NturtDockerContainer(), NturtDockerImage(), NturtDockerPWD()]


if __name__ == "__main__":
    NturtDocker()
