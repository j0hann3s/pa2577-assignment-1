#!/bin/bash

# Prerequisit:
# Must have minikube installed (and all other relevant tool such as kubectl etc...)
# Only tested with Docker driver.

# $ minikube start
# (If restarting minikube, run minikube tunnel again.)

kubectl apply -f k8_database.yaml
kubectl apply -f k8_backend.yaml
kubectl apply -f k8_frontend.yaml

pkill -9 -f 'minikube tunnel'
nohup minikube tunnel > /dev/null 2>&1 & disown

sleep 20

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
    {author: "The best and most beautiful things in the world cannot be seen or even touched - they must be felt with the heart.", quote: "Helen Keller", score: 0},
    {author: "It is during our darkest moments that we must focus to see the light.", quote: "Aristotle", score: 0},
    {author: "Do not go where the path may lead, go instead where there is no path and leave a trail.", quote: "Ralph Waldo Emerson", score: 0},
    {author: "Be yourself; everyone else is already taken.", quote: "Oscar Wilde", score: 0},
    {author: "If life were predictable it would cease to be life and be without flavor.", quote: "Eleanor Roosevelt", score: 0},
    {author: "In the end, it's not the years in your life that count. It's the life in your years.", quote: "Abraham Lincoln", score: 0},
    {author: "Life is a succession of lessons which must be lived to be understood.", quote: "Ralph Waldo Emerson", score: 0},
    {author: "You will face many defeats in life, but never let yourself be defeated.", quote: "Maya Angelou", score: 0},
    {author: "Never let the fear of striking out keep you from playing the game.", quote: "Babe Ruth", score: 0},
    {author: "Life is never fair, and perhaps it is a good thing for most of us that it is not.", quote: "Oscar Wilde", score: 0},
    {author: "The only impossible journey is the one you never begin.", quote: "Tony Robbins", score: 0},
    {author: "In this life we cannot do great things. We can only do small things with great love.", quote: "Mother Teresa", score: 0},
    {author: "Only a life lived for others is a life worthwhile.", quote: "Albert Einstein", score: 0},
    {author: "The purpose of our lives is to be happy.", quote: "Dalai Lama", score: 0}],
    {ordered: false})
EOF

backend_addr=$(kubectl get service quotes-backend-service --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [[ $backend_addr =~ [0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3} ]]; then
    sed -i -E "s|value: \"http://[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}:5000\"|value: \"http://$backend_addr:5000\"|g" k8_frontend.yaml
    kubectl apply -f k8_frontend.yaml
fi

watch -n 1 kubectl get all

# pkill -9 -f 'minikube tunnel'
# kubectl delete --cascade='foreground' -f k8_backend.yaml -f k8_frontend.yaml -f k8_database.yaml
# minikube stop
# sudo chmod 666 /var/run/docker.sock