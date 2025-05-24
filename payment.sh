#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_DIR.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at : $(date)"

#check user has root priveleges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR : Please run with root access $N" | tee -a $LOG_FILE
    exit 1
else
    echo -e "$G You are running with root access $N" | tee -a $LOG_FILE
fi

#VALIDATE function takes input as exit status and what command they try to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else 
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Install Python3 packages"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created.. $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloding payment"

rm -rf /app/*
cd /app
unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "Unzipping payment"

pip3 install -r requirements.txt &>>$LOG_FILE 
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VALIDATE $? "Copying payment"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon Reload"

systemctl enable payment &>>$LOG_FILE
VALIDATE $? "Enabling payment"

systemctl start payment &>>$LOG_FILE
VALIDATE $? "Starting payment"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully.. Time taken : $Y $TOTAL_TIME $N" | tee -a $LOG_FILE
