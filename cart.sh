#!/bin/bash

START_TIME=$(date +%s)
USERID=(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at : $(date)" | tee -a $LOG_FILE

#check the user has root privelege or not
if [ $USERID -ne 0 ]
then
    echo -e "$R Error : Please run with root access $N" | tee -a $LOG_FILE
    exit 1 
else
    echo -e "$G You are running with root access $N" | tee -a $LOG_FILE
fi

#validate function takes input as exit status and what command they try to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is .. $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is .. $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs:20"

dnf install nodejs &>>$LOG_FILE
VALIDATE $? "Installing nodejs"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $G SKIPPIN $N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading cart"

rm -rf /app/*
cd /app
unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "Unzipping cart"

npm install &>>$LOG_FILE
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Copying cart servive"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable cart &>>$LOG_FILE
systemctl start cart
VALIDATE $? "Starting cart"

END_TIME=$(date +&s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME $N" | tee -a $LOG_FILE
