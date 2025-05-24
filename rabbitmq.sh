#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
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

#check user has root priveleges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR :: Please run with root access $N" | tee -a $LOG_FILE  
    exit 1
else
    echo -e "$G You are running with root access $N" | tee -a $LOG_FILE
fi 

echo "Please enter rabbitmq password to setup"
read -s RABBITMQ_PASSWD

#Validate function takes input as exit status and what command they try to install
Validate(){
    if [ $1 -eq 0 ]
    then 
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE 
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo 
Validate $? "Copying rabbitmq"

dnf install rabbitmq-server -y &>>$LOG_FILE
Validate $? "Installing rabbitmq server"

systemctl enable rabbitmq-server &>>$LOG_FILE
Validate $? "Enabling rabbitmq"

systemctl start rabbitmq-server &>>$LOG_FILE
Validate $? "Starting rabbitmq"

rabbitmqctl add_user roboshop $RABBITMQ_PASSWD &>>$LOG_FILE
rabbitmqctl set permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully .. $Y Time taken : $TOTAL_TIME seconds $N" | tee -a $LOG_FILE

