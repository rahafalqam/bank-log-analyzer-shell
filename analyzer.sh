#!/bin/bash


#RahafAlqam 1232633


LOG_FILE="bank_server.log"


#to check file
validate_log_file()
{
    if [ ! -f "$LOG_FILE" ] #check if LOG_FILE is an ordinary file (normal file)
    then
        echo "Log file not found!"
        exit 1
    fi
}
validate_log_file


    get_level() #get only level from log file 
    {
        echo "$1" | cut -d']' -f2 | tr -d '[] '   
    }

    get_timestamp() #get only timee from log file 
    {
        echo "$1" | cut -d']' -f1 | tr -d '['
    }

    get_user() #get only user from log file
    {
        echo "$1" | cut -d']' -f4 | tr -d '['
    }

    get_ip() #get only ip from log file
    {
        echo "$1" | cut -d']' -f5 | tr -d '['
    }

    get_module() #get only module from log file
    {
        echo "$1" | cut -d']' -f6 | tr -d '['
    }
    get_message() #get only massage from log file
    {
        echo "$1" | cut -d'-' -f2-
    }


#1
failed_login_report()
{
    echo " Failed Login Report "

    failed_logins=$(grep "AUTH" "$LOG_FILE" | grep "ERROR" | grep "Failed login attempt")

    total=$(echo "$failed_logins" | grep -c "Failed login attempt") #-c for count

    echo "Total failed login attempts: $total"

    echo ""
    echo "Attempts by IP:"

    echo "$failed_logins" | cut -d']' -f5 | tr -d '[' | sort | uniq -c 

    echo ""
    echo "Attempts by USER:"

    echo "$failed_logins" | awk -F'for user ' '{print $2}' | awk '{print $1}' | sort | uniq -c
   
    echo ""
    echo "Possible brute-force sources:"

    echo "$failed_logins" | cut -d']' -f5 | tr -d '[' | sort | uniq -c | awk '$1 >= 3'
}


#5
critical_events_report()
{
    echo " Critical Events Report "

    grep "CRITICAL" "$LOG_FILE" | sort
}


#9
general_summary()
{
    echo " General Log Summary "

    total=$(wc -l < "$LOG_FILE")

    echo "Total number of lines: $total"

    echo ""
    echo "Events by Log Level:"

    echo "INFO: $(grep -c "INFO" "$LOG_FILE")"
    echo "WARNING: $(grep -c "WARNING" "$LOG_FILE")"
    echo "ERROR: $(grep -c "ERROR" "$LOG_FILE")"
    echo "CRITICAL: $(grep -c "CRITICAL" "$LOG_FILE")"

    echo ""
    echo "Busiest Module:"

    grep "^\[" "$LOG_FILE" | cut -d']' -f6 | tr -d '[' | sort | uniq -c | sort -nr | head -1 #n acording digit , r DESC

}


#2
query_activity_summary()
{
    echo " Query Activity Summary "

    query_logs=$(grep "QUERY" "$LOG_FILE")

    total_queries=$(echo "$query_logs" | wc -l)

    select_count=$(echo "$query_logs" | grep "SELECT" | wc -l)

    update_count=$(echo "$query_logs" | grep "UPDATE" | wc -l)

    insert_count=$(echo "$query_logs" | grep "INSERT" | wc -l)

    delete_count=$(echo "$query_logs" | grep "DELETE" | wc -l)


    echo "Total Queries: $total_queries"
    echo "SELECT: $select_count"
    echo "UPDATE: $update_count"
    echo "INSERT: $insert_count"
    echo "DELETE: $delete_count"
}


#3
slow_query_detector()
{
    echo " Slow Query Detector "

    slow_queries=$(grep "WARNING" "$LOG_FILE" | grep "Slow query")

    echo "Total slow-query warnings: $(echo "$slow_queries" | wc -l)"
    echo ""

    printf "%-20s %-12s %-20s %s\n" "TIMESTAMP" "USER" "EXECUTION TIME" "MESSAGE"

    echo "$slow_queries" | while read line #each line at parameter line
    do
        timestamp=$(echo "$line" | awk -F'[][]' '{print $2}')

        user=$(echo "$line" | awk -F'[][]' '{print $8}')

        time=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+ seconds')

        message=$(echo "$line" | cut -d'-' -f2-)

        printf "%-20s %-12s %-20s %s\n" "$timestamp" "$user" "$time" "$message"

    done
}

#4
transaction_report()
{
    echo " Transaction Report "

    transactions=$(grep "TRANSACTION" "$LOG_FILE")

    deposits=$(echo "$transactions" | grep -i "Deposit" | wc -l) #-i ignore upper or lower case

    withdrawals=$(echo "$transactions" | grep -i "Withdrawal" | wc -l)

    declined=$(echo "$transactions" | grep -i "Declined" | wc -l)

    rollbacks=$(echo "$transactions" | grep -i "Rollback" | wc -l)


    deposit_amount=$(echo "$transactions" | grep -i "Deposit" | grep -o 'amount: [0-9]\+' | awk '{sum+=$2} END {print sum}')

    withdrawal_amount=$(echo "$transactions" | grep -i "Withdrawal" | grep -o 'amount: [0-9]\+' | awk '{sum+=$2} END {print sum}')


    echo "Deposits: $deposits"
    echo "Total Deposit Amount: $deposit_amount"

    echo "Withdrawals: $withdrawals"
    echo "Total Withdrawal Amount: $withdrawal_amount"

    echo "Declined Transactions: $declined"

    echo "Rollbacks: $rollbacks"
}


#6
user_activity_report()
{
    echo " User Activity Report "

    read -p "Enter username: " username #-p print message before read

    grep "^\[" "$LOG_FILE" | while read line
    do
	user=$(echo "$line" | cut -d']' -f4 | tr -d '[' )

	if [ "$user" = "$username" ]
	then
            echo "$line"
	fi

    done 
}


#7
session_report()
{
    echo " Session Report "

    echo "SESSION        USER        LOGIN TIME              LOGOUT TIME             DURATION"

    grep "AUTH" "$LOG_FILE" | grep "SESSION_" | while read line
    do
        session=$(echo "$line" | cut -d']' -f3 | tr -d '[')
        user=$(echo "$line" | cut -d']' -f4 | tr -d '[')
        time=$(echo "$line" | cut -d']' -f1 | tr -d '[')
        message=$(echo "$line" | cut -d'-' -f2-)

        if echo "$message" | grep -qi "login"
        then
            login_time="$time"

            logout=$(grep "$session" "$LOG_FILE" | grep "logout")

            if [ -n "$logout" ]#-n : not empty
            then
                logout_time=$(echo "$logout" | cut -d']' -f1 | tr -d '[')

                start=$(date -d "$login_time" +%s)#-d date from string
                end=$(date -d "$logout_time" +%s)

                duration=$((end-start))
                minutes=$((duration/60))

                echo "$session    $user    $login_time    $logout_time    $minutes minutes"

            else
                echo "$session    $user    $login_time    N/A    Active"
            fi

        fi

    done
}

#8
events_per_hour_report()
{
    echo " Events Per Hour Report "

    grep "^\[" "$LOG_FILE" | cut -d' ' -f2 | cut -d':' -f1 | tr -d ']' | sort | uniq -c | while read count hour  
    do
         echo "$hour : $count events"
    done
}

#10
run_all_reports()
{
    failed_login_report
    query_activity_summary
    slow_query_detector
    transaction_report
    critical_events_report
    session_report
    events_per_hour_report
    general_summary
}


while true
do
echo "------------------------------------"
echo "     Bank Log Analyzer Menu    "
echo ""
echo "1. Failed Login"
echo "2. Query Activity"
echo "3. Slow Query"
echo "4. Transaction Report"
echo "5. Critical Events"
echo "6. User Activity"
echo "7. Session Report"
echo "8. Events Per Hour"
echo "9. General Summary"
echo "10. Run All Reports"
echo "11. Exit"

echo ""
read choice
echo ""

case $choice in

1) failed_login_report ;;
2) query_activity_summary ;;
3) slow_query_detector ;;
4) transaction_report ;;
5) critical_events_report ;;
6) user_activity_report ;;
7) session_report ;;
8) events_per_hour_report ;;
9) general_summary ;;
10) run_all_reports ;;
11)  exit ;;
*) echo "Invalid choice" ;;


esac

done


# NOTE : We use two commands are not covered in the manual and slides.
# 1) awk:
#   read text or num. on it and deal with each line asume
# it divide into columns  and can make operation on it.

# 2) grep -o:
#   print only what exactly like our format.
