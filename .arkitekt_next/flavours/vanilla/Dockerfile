FROM mathworks/matlab:r2024b


RUN pip install "arkitekt-next[all]==0.8.59"
RUN pip install tifffile

USER root
COPY App.m /home/matlab/
COPY karl.m /home/matlab/
COPY .arkitekt_next /home/matlab/.arkitekt_next
COPY app.py /home/matlab/

RUN chown -R matlab:matlab /home/matlab/.arkitekt_next
USER matlab
WORKDIR /home/matlab

# We need to overwrite the entrypoint of the parent image
ENTRYPOINT []
