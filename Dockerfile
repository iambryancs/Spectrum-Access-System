# Build 
FROM continuumio/miniconda3:4.10.3p1 as build

ARG PYTHON_VER=3.7

WORKDIR /opt/app

RUN apt update \
        && apt install -y build-essential

RUN conda create --name "winnf3" python=${PYTHON_VER}

# We can't activate a conda env non-interactively
# or in a CI env, so let's use env targetting
# by passing the `-n` option to conda commands

RUN conda run -n "winnf3" pip3 install six

COPY ./src/harness/reference_models/propagation .

RUN conda run -n winnf3 make -C itm all
RUN conda run -n winnf3 make -C ehata all

# Runtime
FROM continuumio/miniconda3:4.10.3p1

ARG PYTHON_VER=3.7
ENV COMMON_DATA=/mnt/SAS-Data2/SAS-Data/

WORKDIR /opt/app

RUN conda create --name "winnf3" python=${PYTHON_VER}
RUN conda create --name "crl" python=2.7

# We can't activate a conda env non-interactively
# or in a CI env, so let's use env targetting
# by passing the `-n` option to conda commands

RUN conda install -n "winnf3" -y numpy \
        shapely \
        gdal \
        lxml \
        jsonschema \
        matplotlib \
        cartopy \
        cryptography \
        pyopenssl \
        pycurl

RUN conda run -n "winnf3" pip3 install pygc \
        pykml \
        xlsxwriter \
        jwt \
        portpicker \
        psutil \
        ftputil \
        pytz

RUN conda run -n "crl" pip install six

COPY . .

COPY --from=build /opt/app/itm/*.so ./src/harness/reference_models/propagation/itm/
COPY --from=build /opt/app/ehata/*.so ./src/harness/reference_models/propagation/ehata/

RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]

# Default python script pass to the entrypoint
CMD ["src/harness/test_main.py"]
