import json
import urllib.request
import urllib.error
import ssl

BASE_URL = "https://requestapi.co/api/v2/"


def lambda_handler(event, context):
    # APIのパスとパラメータをeventから受け取る
    api_path = event["apiPath"]
    param = event["parameters"][0]["value"]

    endpoint = BASE_URL + "param/"
    url = endpoint + param
    print(url)

    if api_path == "/search":
        try:
            # カスタムヘッダーを設定
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
            }

            # リクエストオブジェクトを作成
            req = urllib.request.Request(url, headers=headers)

            # SSL証明書の検証をバイパス（注意: セキュリティリスクがあります）
            context = ssl._create_unverified_context()

            # APIの実行
            with urllib.request.urlopen(req, context=context) as response:
                response_data = response.read()

            response = json.loads(response_data.decode('utf-8'))

            # 以下、レスポンス処理は変更なし
            formatted_types = [ translate_info("type", poke_type["type"]["name"]) for poke_type in response["types"] ]
            pokemon_type = "/".join(formatted_types)

            formatted_abilities = [ translate_info("ability", ability["ability"]["name"]) + "*" if ability["is_hidden"] else translate_info("ability", ability["ability"]["name"]) for ability in response["abilities"] ]
            abilities = "/".join(formatted_abilities)

            result = {
                "id": response["id"],
                # レスポンスに画像URLを追加
                "画像URL": response["sprites"]["other"]['official-artwork']['front_default'],
            }
            response_body = {"application/json": {"body": json.dumps(result, ensure_ascii=False)}}
            http_status_code = 200
            print(result)
        except urllib.error.URLError as e:
            print(e)
            print("error発生")
            response_body = {"application/json": {"body": json.dumps({"errorMessage": f"APIリクエストエラー: {str(e)}"}, ensure_ascii=False)}}
            http_status_code = 400

        action_response = {
            "actionGroup": event["actionGroup"],
            "apiPath": event["apiPath"],
            "httpMethod": event["httpMethod"],
            "httpStatusCode": http_status_code,
            "responseBody": response_body,
        }
    else:
        response_body = {"application/json": {"body": json.dumps({"errorMessage": "エラーが発生しました"}, ensure_ascii=False)}}

        action_response = {
            "actionGroup": event["actionGroup"],
            "apiPath": event["apiPath"],
            "httpMethod": event["httpMethod"],
            "httpStatusCode": 400,
            "responseBody": response_body,
        }

    return {
        "messageVersion": "1.0",
        "response": action_response
    }


def translate_info(info, value):
    '''
    変換したい情報のタイプと値を引数として、日本語に変換して返す
    ※ 変換できない場合なそのままの値を返す
    param:
    - info: 変換したい情報のタイプ（ type or ability or pokemon-species ）
    - value: 変換したい値
    '''
    # APIを実行してinfo/valueに対応した情報を取得
    url = f"{BASE_URL}{info}/{value}"

    # カスタムヘッダーを設定
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
    }

    try:
        # リクエストオブジェクトを作成し、カスタムヘッダーを設定
        req = urllib.request.Request(url, headers=headers)

        with urllib.request.urlopen(req) as response:
            if response.getcode() == 200:
                data = json.loads(response.read().decode())
                # レスポンスの中に日本語の情報が含まれているので、取り出して返す
                for item in data['names']:
                    if item['language']['name'] == 'ja-Hrkt':
                        return item['name']
                return info
            else:
                print(f"エラー: HTTPステータスコード {response.getcode()}")
                return info
    except urllib.error.HTTPError as e:
        print(f"HTTPエラーが発生しました: {e.code} {e.reason}")
        return info
    except urllib.error.URLError as e:
        print(f"URLエラーが発生しました: {e.reason}")
        return info
    except Exception as e:
        print(f"予期せぬエラーが発生しました: {e}")
        return info
