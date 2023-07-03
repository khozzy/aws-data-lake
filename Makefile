.PHONY: lint

lint:
	terraform fmt infra
	(cd code; poetry run black .)