# Data-Lake on AWS


## Note about AWS CLI usage
In this document I'm using [aws-vault](https://github.com/99designs/aws-vault) to manage AWS security credential chain with a profile name `personal-tf`.

```bash
terraform init
aws-vault exec personal-tf -- terraform apply
```

## Synthetic data generation
Python data generators reside in [/code](/code) folder.

```bash
poetry config settings.virtualenvs.in-project true
poetry install
```