
ENDPOINT:=http://localhost:8000
TABLENAME:=TodoTest

create_table:
	@aws dynamodb create-table \
		--endpoint-url $(ENDPOINT) \
		--cli-input-json file://dynamo/create_table.json

create_partition_only_table:
	@aws dynamodb create-table \
		--endpoint-url $(ENDPOINT) \
		--cli-input-json file://dynamo/create_table_partition_key_only.json



create_todo:
	@aws dynamodb put-item \
		--endpoint-url $(ENDPOINT) \
		--item file://dynamo/create_todo.json \
		--table-name $(TABLENAME)

scan_todos:
	@aws dynamodb scan \
		--endpoint-url $(ENDPOINT) \
		--table-name $(TABLENAME)

get_todo:
	@aws dynamodb query \
		--endpoint-url $(ENDPOINT) \
		--table-name $(TABLENAME) \
		--key-condition-expression "ListID = :listID and TodoID = :todoID" \
		--expression-attribute-values '{":listID": {"S": "list"}, ":todoID": {"S": "9D1007B4-D386-42A3-99A1-31469983443C"}}'

