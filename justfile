default:
    @just --list

lint:
    pixi run mojo format --check src tests

check:
    pixi run mojo test tests

update:
    pixi update
