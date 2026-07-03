for j in {1..10}; do  
    for i in {1..1000}; do  
        curl -s -o /dev/null -w "%{http_code}\n" http://a2f333cf2f0d443559889efe98e5bd74-838294703.us-east-1.elb.amazonaws.com/ &  
    done  
    wait  # Wait for all background curl processes to finish before next iteration
done