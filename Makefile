.PHONY: test migrate

test:
	busted

migrate:
	lapis migrate
	make schema.sql

schema.sql:
	pg_dump -s -U postgres ludumdare > schema.sql
	pg_dump -a -t lapis_migrations -U postgres ludumdare >> schema.sql

init_schema:
	createdb -U postgres ludumdare
	cat schema.sql | psql -U postgres ludumdare


test_db:
	-dropdb -U postgres ludumdare_test
	createdb -U postgres ludumdare_test
	pg_dump -s -U postgres ludumdare | psql -U postgres ludumdare_test
	pg_dump -a -t lapis_migrations -U postgres ludumdare | psql -U postgres ludumdare_test

lint:
	git ls-files | grep '\.moon$$' | grep -v config.moon | xargs -n 100 moonc -l

checkpoint:
	mkdir -p dev_backup
	pg_dump -F c -U postgres ludumdare > dev_backup/$$(date +%F_%H-%M-%S).dump

annotate_models:
	lapis annotate $$(find models -type f | grep moon$$)

