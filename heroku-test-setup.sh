git clone https://github.com/theory/pgtap.git
cd pgtap
make
#make installcheck
make install
cd ..
./setup.sh $DATABASE_URL