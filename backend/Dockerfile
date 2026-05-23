FROM public.ecr.aws/lambda/python:3.11

# Copy requirements.txt
COPY requirements.txt ${LAMBDA_TASK_ROOT}

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY app ${LAMBDA_TASK_ROOT}/app

# Set the CMD to the Mangum handler
CMD [ "app.main.handler" ]
