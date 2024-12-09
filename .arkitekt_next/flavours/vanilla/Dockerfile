FROM mathworks/matlab:r2024b


RUN pip install "arkitekt-next[all]==0.8.59"
RUN pip install tifffile


COPY App.m /home/matlab/
COPY karl.m /home/matlab/
COPY .arkitekt_next /home/matlab/.arkitekt_next
COPY app.py /home/matlab/

WORKDIR /home/matlab

# We need to overwrite the entrypoint of the parent image
ENTRYPOINT []
