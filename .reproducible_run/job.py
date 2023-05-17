import yaml
import argparse
from sagemaker import get_execution_role
from sagemaker.estimator import Framework


def get_config():
    with open("environment/config.yaml") as f:
        config = yaml.load(f, Loader=yaml.SafeLoader)
    return config


def get_iam_role():
    iam_role = get_execution_role()
    return iam_role


class ContainerEstimator(Framework):
    def __init__(
        self,
        entry_point,
        framework_version=None,
        py_version=None,
        source_dir=None,
        hyperparameters=None,
        image_uri=None,
        distribution=None,
        **kwargs,
    ):
        super(ContainerEstimator, self).__init__(
            entry_point, source_dir, hyperparameters, image_uri=image_uri, **kwargs
        )
        self.framework_version = framework_version
        self.py_version = None

    def _configure_distribution(self, distributions):
        return None

    def create_model(
        self,
        model_server_workers=None,
        role=None,
        vpc_config_override=None,
        entry_point=None,
        source_dir=None,
        dependencies=None,
        image_uri=None,
        **kwargs,
    ):
        return None


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--job_name", type=str, default="")
    parser.add_argument("--container_image", type=str, default="")
    parser.add_argument("--entrypoint", type=str, default="")
    parser.add_argument("--output_path", type=str, default="")
    args, _ = parser.parse_known_args()

    # IAM ROLE
    iam_role = get_iam_role()

    # CONFIG
    config = get_config()

    # RUN TRAINING JOB
    estimator = ContainerEstimator(
        role=iam_role,
        image_uri=args.container_image,
        entry_point=args.entrypoint,
        source_dir=".",
        instance_count=1,
        # instance_type=config["run"]["instance_type"],
        environment={"S3_OUTPUT": f"{args.output_path}/{args.job_name}/"},
        instance_type="local",
        disable_profiler=True,
        output_path=args.output_path,
    )
    estimator.fit(job_name=args.job_name)
