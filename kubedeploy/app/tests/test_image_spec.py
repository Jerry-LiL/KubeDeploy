"""The image contract the pipeline scans and ships."""

from pathlib import Path


def test_dockerfile_is_multistage_and_nonroot():
    text = Path("kubedeploy/app/Dockerfile").read_text()
    froms = [line for line in text.splitlines() if line.startswith("FROM ")]
    assert len(froms) >= 2
    user_lines = [line for line in text.splitlines() if line.startswith("USER ")]
    assert user_lines[-1].strip() == "USER 10001:10001"
