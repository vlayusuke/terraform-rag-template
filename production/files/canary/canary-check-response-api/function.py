from selenium import webdriver
import logging
import traceback

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def request_api_monitoring():
    browser = webdriver.Chrome()
    browser.get('https://rag.vlayusuke.net/api/v2/')  # Replace with the actual URL you want to check
    browser.quit()

def canary_handler(event, context):
    try:
        logger.info("Starting Selenium script execution.")

        request_api_monitoring()

        logger.info("Selenium script executed successfully.")

        return {
            "statusCode": 200,
            "message": 'Completed request API monitoring.'
        }

    except Exception as e:
        logger.error(e)
        logger.error(traceback.format_exc())

        return {
            "statusCode": 500,
            "message": 'An error occurred at request API monitoring.'
        }
