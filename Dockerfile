FROM gpio-base:latest  
ADD ./app.py ./app.py

CMD ["python", "app.py"]  
