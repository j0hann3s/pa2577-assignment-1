import os

import requests
from flask import Flask, render_template, url_for

app = Flask(__name__, template_folder=".")


@app.route("/", methods=["GET"])
def index():
    """
    Landing page of web application.
    """
    current_quote = get_quote()
    return render_template(
        "./index.html",
        top_page=url_for("top"),
        quote=current_quote[0],
        up_link=current_quote[1],
        down_link=current_quote[2],
    )


@app.route("/top", methods=["GET"])
def top():
    """
    Page with top voted quotes.
    """
    return render_template("./top.html", quotes_list=get_top_list())


def get_quote():
    """
    Get random quote from Backend API and up-vote/down-vote links of the quote.
    """
    response = requests.get(os.environ["BACKEND_URI"] + "/next")
    quote_string = (
        '"' + response.json()[0]["quote"] + '" - ' + response.json()[0]["author"]
    )
    quote_up_link = (
        f"{os.environ['EXTERNAL_BROWSER_URI']}/{response.json()[0]['_id']['$oid']}/up"
    )
    quote_down_link = (
        f"{os.environ['EXTERNAL_BROWSER_URI']}/{response.json()[0]['_id']['$oid']}/down"
    )
    return (quote_string, quote_up_link, quote_down_link)


def get_top_list():
    """
    Get top quote list sorted by popularity from Backend API.
    """
    response = requests.get(os.environ["BACKEND_URI"] + "/list")
    return_list = []
    for quote in response.json():
        return_list.append(
            f"Score: {quote['score']} - \"{quote['quote']}\" - {quote['author']}"
        )
    return return_list


if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True)
