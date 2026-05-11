import os
import boto3
import json
import uuid

AGENT_ID = os.environ['AGENT_ID']
AGENT_ALIAS_ID = os.environ['AGENT_ALIAS_ID']


def chat(message, session_id):

    # Agent用のSDKが用意されている
    client = boto3.client("bedrock-agent-runtime")

    # Agentを実行する
    response = client.invoke_agent(
        inputText=message,
        agentId=AGENT_ID,             # AgentのID
        agentAliasId=AGENT_ALIAS_ID,  # AgentのaliasのID
        sessionId=session_id,
        enableTrace=False
    )

    # Agentの実行結果を取得し、返す
    results = response['completion']
    retval = ""
    for result in results:
        if 'chunk' in result:
            retval = result['chunk']['bytes'].decode("utf-8")

    return retval


def lambda_handler(event, context):
    print(event)

    message = event['queryStringParameters']['input_text']
    session_id = str(uuid.uuid4())    # ランダムなsession_idを生成
    resp = chat(message, session_id)
    print(event)
    print(f"resp: {resp}")

    return {
        "statusCode": 200,
        "body": f"{resp}",
    }
