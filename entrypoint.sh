#!/bin/bash

set -eux

# Move geo counties to counties.old
mv /opt/app/data/counties /opt/app/data/counties.old

# Set symlinks
# https://github.com/Wireless-Innovation-Forum/Common-Data/blob/master/README.md#data-integration-into-sas
# We expect a Common-Data volume to be mounted at $COMMON_DATA path

if [[ -d "$COMMON_DATA" ]]; then
    ln -s $COMMON_DATA/ned /opt/app/data/geo/ned
    ln -s $COMMON_DATA/nlcd /opt/app/data/geo/nlcd
    ln -s $COMMON_DATA/census /opt/app/data/census
    ln -s $COMMON_DATA/census /opt/app/data/counties
    ln -s $COMMON_DATA/census /opt/app/data/county
else
    echo -e "$(tpud setaf 1)ERR: No Common-Data found at $COMMON_DATA\!"
    exit 1
fi


### sas.cfg
# 1. Move sas.cfg to sas.cfg.old
mv $SAST_DIR/sas.cfg $SAST_DIR/sas.cfg.old

# 2. Set symlink for sas.cfg
ln -s $COMMON_DATA/sast/sas.cfg $SAST_DIR/sas.cfg

### test.cfg
# 1. Move test.cfg to test.cfg.old
mv $SAST_DIR/test.cfg $SAST_DIR/test.cfg.old

# 2. Set symlink for test.cfg
ln -s $COMMON_DATA/sast/test.cfg $SAST_DIR/test.cfg

### Logs
# Set symlink for logs
ln -s $COMMON_DATA/sast/logs $SAST_DIR/logs

### Time shortening FDB.8
# 1. Move sas.py to sas.py.old
mv $SAST_DIR/sas.py $SAST_DIR/sas.py.old

# 2. Set symlink for sas.py with time shortening applied
ln -s $COMMON_DATA/sast/sas.py $SAST_DIR/sas.py

### Testcases
# 1. Move testcases to testcases.old
mv $SAST_DIR/testcases $SAST_DIR/testcases.old

# 2. Set symlink for testcases dir
ln -s $COMMON_DATA/sast/testcases $SAST_DIR/testcases

### Certs
# 1. Move certs to cets.old
mv $SAST_DIR/certs $SAST_DIR/certs.old


# 2. Copy certs (symlink won't work)
cp -R $COMMON_DATA/sast/certs $SAST_DIR/certs

# Run test configs
conda run -n winnf3 --no-capture-output --cwd reference_models python3 test_config.py
conda run -n winnf3 --no-capture-output --cwd reference_models python3 -m unittest discover -p '*_test.py'

conda run -n winnf3 python3 $@
