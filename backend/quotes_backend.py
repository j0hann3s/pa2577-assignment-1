import os

from bson.json_util import dumps
from bson.objectid import ObjectId
from flask import Flask
from pymongo import MongoClient

app = Flask(__name__)

mongo_client = MongoClient(os.environ["MONGODB_URI"])
quotes_db = mongo_client["quotes_db"]
quotes_col = quotes_db["quotes_col"]


@app.route("/list", methods=["GET"])
def list_quotes():
    """
    Return a list of all quotes inside the database in order of popularity.
    """
    cursor = quotes_col.find().sort({"score": -1})
    return dumps(cursor)


@app.route("/next", methods=["GET"])
def next_quote():
    """
    Return a random new quote from the database.
    """
    cursor = quotes_col.aggregate([{"$sample": {"size": 1}}])
    return dumps(cursor)


@app.route("/<uuid>/up", methods=["POST"])
def vote_up(uuid):
    """
    Vote up the passed quote.
    """
    if quotes_col.find_one({"_id": ObjectId(uuid)}) is None:
        return "", 404
    quotes_col.find_one_and_update(
        filter={"_id": ObjectId(uuid)}, update={"$inc": {"score": 1}}
    )
    return "", 200


@app.route("/<uuid>/down", methods=["POST"])
def vote_down(uuid):
    """
    Vote down the passed quote.
    """
    if quotes_col.find_one({"_id": ObjectId(uuid)}) is None:
        return "", 404
    quotes_col.find_one_and_update(
        filter={"_id": ObjectId(uuid)}, update={"$inc": {"score": -1}}
    )
    return "", 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True)
