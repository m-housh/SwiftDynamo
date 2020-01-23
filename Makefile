
ENDPOINT:=http://localhost:8000
TABLENAME:=TodoTest

create_table:
	@aws dynamodb create-table \
		--endpoint-url $(ENDPOINT) \
		--cli-input-json file://dynamo/create_table.json


create_todo:
	@aws dynamodb put-item \
		--endpoint-url $(ENDPOINT) \
		--item file://dynamo/create_todo.json \
		--table-name $(TABLENAME)

scan_todos:
	@aws dynamodb scan \
		--endpoint-url $(ENDPOINT) \
		--table-name $(TABLENAME)
