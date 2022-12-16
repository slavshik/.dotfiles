SSL_PATH=~/TODO add path
function https() {
    http-server -S -C $SSL_PATH/key.pem -K $SSL_PATH/key.key -p 8080
}
