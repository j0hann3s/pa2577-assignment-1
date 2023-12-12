#!/bin/bash

# Prerequisit:
# Must have minikube installed (and all other relevant tool such as kubectl etc...)
# Only tested with Docker driver.

# $ minikube start
# (If restarting minikube, run minikube tunnel again.)

pkill -9 -f 'minikube tunnel'
nohup minikube tunnel > /dev/null 2>&1 & disown

kubectl apply -f k8_database.yaml
kubectl apply -f k8_backend.yaml
kubectl apply -f k8_frontend.yaml

sleep 30

# Load initial data into database.
db_addr=$(kubectl get service quotes-database-service --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')
mongosh "$db_addr":27017 <<EOF
use quotes_db
db.quotes_col.insertMany(
    [{author: "Mahatma Gandhi", quote: "You must be the change you wish to see in the world.", score: 0},
    {author: "Mother Teresa", quote: "Spread love everywhere you go. Let no one ever come to you without leaving happier.", score: 0},
    {author: "Franklin D. Roosevelt", quote: "The only thing we have to fear is fear itself.", score: 0},
    {author: "Martin Luther King Jr.", quote: "Darkness cannot drive out darkness: only light can do that. Hate cannot drive out hate: only love can do that.", score: 0},
    {author: "Eleanor Roosevelt", quote: "Do one thing every day that scares you.", score: 0},
    {author: "Benjamin Franklin", quote: "Well done is better than well said.", score: 0},
    {author: "Helen Keller", quote: "The best and most beautiful things in the world cannot be seen or even touched - they must be felt with the heart.", score: 0},
    {author: "Aristotle", quote: "It is during our darkest moments that we must focus to see the light.", score: 0},
    {author: "Ralph Waldo Emerson", quote: "Do not go where the path may lead, go instead where there is no path and leave a trail.", score: 0},
    {author: "Oscar Wilde", quote: "Be yourself; everyone else is already taken.", score: 0},
    {author: "Eleanor Roosevelt", quote: "If life were predictable it would cease to be life and be without flavor.", score: 0},
    {author: "Abraham Lincoln", quote: "In the end, it's not the years in your life that count. It's the life in your years.", score: 0},
    {author: "Ralph Waldo Emerson", quote: "Life is a succession of lessons which must be lived to be understood.", score: 0},
    {author: "Maya Angelou", quote: "You will face many defeats in life, but never let yourself be defeated.", score: 0},
    {author: "Babe Ruth", quote: "Never let the fear of striking out keep you from playing the game.", score: 0},
    {author: "Oscar Wilde", quote: "Life is never fair, and perhaps it is a good thing for most of us that it is not.", score: 0},
    {author: "Tony Robbins", quote: "The only impossible journey is the one you never begin.", score: 0},
    {author: "Mother Teresa", quote: "In this life we cannot do great things. We can only do small things with great love.", score: 0},
    {author: "Albert Einstein", quote: "Only a life lived for others is a life worthwhile.", score: 0},
    {author: "Dalai Lama", quote: "The purpose of our lives is to be happy.", score: 0}],
    {ordered: false})
EOF

backend_addr=$(kubectl get service quotes-backend-service --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [[ $backend_addr =~ [0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3} ]]; then
    sed -i -E "s|value: \"http://[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}:5000\"|value: \"http://$backend_addr:5000\"|g" k8_frontend.yaml
    kubectl apply -f k8_frontend.yaml
fi

# watch -n 1 kubectl get all
# pkill -9 -f 'minikube tunnel'
# kubectl delete --cascade='foreground' -f k8_backend.yaml -f k8_frontend.yaml -f k8_database.yaml
# minikube stop