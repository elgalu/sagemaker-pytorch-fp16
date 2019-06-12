# sagemaker-pytorch-fp16

SageMaker-PyTorch-FP16 is an open source docker setup that allows Amazon SageMaker jobs to take advantage of mixed-precision faster GPU training while using PyTorch in combination with the [NVidia/Apex](https://github.com/NVIDIA/apex) library.

This project is based on [sagemaker-pytorch-container](https://github.com/aws/sagemaker-pytorch-container) however by using that project as-provided we got `torch.matmul` in mixed-precision training slow downs by a huge magnitude so we decided to create this repo that fixes the problem.

## Getting Started

### Prerequisites
+ Up-to-date docker version
+ Code compatible with latest PyTorch
+ Amazon SageMaker account

### Setup
    pip install -e .[test]
    pip install torch torchvision fastai
    pip install --upgrade pip wheel

### Build the base images
The "base" Dockerfile takes care of compiling all required up-to-date packages which is incredible time consuming.

    docker build -t elgalu/pytorch-base0-1.1.0-gpu-py3:local -f docker/py3/Dockerfile.0.gpu .
    docker build -t elgalu/pytorch-base1-1.1.0-gpu-py3:local -f docker/py3/Dockerfile.1.gpu .
    docker build -t elgalu/pytorch-base1-1.1.0-gpu-py3:local -f docker/py3/Dockerfile.2.gpu .

### Build the wheel
The "final" Dockerfile encompass the installation of the SageMaker specific support code.

    python setup.py bdist_wheel

### Build the final image
Change `AWS_ACCOUNT_NUMBER` accordingly.

    AWS_ACCOUNT_NUMBER=012345678901
    img="${AWS_ACCOUNT_NUMBER}.dkr.ecr.eu-central-1.amazonaws.com/sagemaker-pytorch-1.1.0-gpu-py3:cu101"
    docker build -t ${img} -f docker/py3/Dockerfile.2.gpu .

### Push the final image
Change `AWS_ACCOUNT_NUMBER` accordingly.

    AWS_ACCOUNT_NUMBER=012345678901
    $(aws ecr get-login --profile=default --region=eu-central-1 --registry-ids=${AWS_ACCOUNT_NUMBER} --no-include-email)
    aws ecr create-repository --profile=default --region=eu-central-1 --repository-name sagemaker-pytorch-1.1.0-gpu-py3
    docker push ${img}


## Running the tests
Running the tests requires installation of the SageMaker PyTorch Container code and its test dependencies.

    pip install -e .[test]

### Unit Tests
All test instructions should be run from the top level directory

    pytest test/unit

You can use tox to run unit tests as well as flake8 and code coverage

    tox


### Local Integration Tests
Required arguments for integration tests are found in test/conftest.py

    pytest test/integration/local --docker-base-name=pytorch-1:1.1.0-gpu-py3 \
                      --tag cu101 \
                      --py-version 3 \
                      --framework-version 1.1.0 \
                      --processor cpu

## Contributing
Please read CONTRIBUTING.md

## License
Licensed under the Apache 2.0 License. It is copyright 2018 Amazon .com, Inc. or its affiliates. All Rights Reserved. The license is available at: http://aws.amazon.com/apache2.0/
