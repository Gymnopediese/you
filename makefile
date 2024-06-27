main:
	python html_to_motoko/main.py -s html -d src/frontend
	dfx deploy alex --ic --argument '("alex")'