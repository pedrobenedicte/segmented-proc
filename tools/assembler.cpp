#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <stdlib.h>
#include <sstream>
using namespace std;
 

short nregister(string str){
	short ret;
	if (str == "r0" || str == "r0," || str == "(r0)") ret = 0b000;
	else if (str == "r1" || str == "r1," || str == "(r1)") ret = 0b001;
	else if (str == "r2" || str == "r2," || str == "(r2)") ret = 0b010;
	else if (str == "r3" || str == "r3," || str == "(r3)") ret = 0b011;
	else if (str == "r4" || str == "r4," || str == "(r4)") ret = 0b100;
	else if (str == "r5" || str == "r5," || str == "(r5)") ret = 0b101;
	else if (str == "r6" || str == "r6," || str == "(r6)") ret = 0b110;
	else if (str == "r7" || str == "r7," || str == "(r7)") ret = 0b111;
	else ret = -1;

	return ret;
}

short read_loads(istringstream &in) {
	string str;
	short ret = 0;
	short nreg;

	in >> nreg;
	ret |= (0x1F&nreg) << 6;

	in >> str;
	nreg = nregister(str);
	if (nreg == -1) return -1;
	ret |= nreg;

	in >> str;
	if (str != "->") return -1;

	in >> str;
	nreg = nregister(str);
	if (nreg == -1) return -1;
	ret |= nreg << 3;

	return ret;
}

short read_stores(istringstream &in) {
	string str;
	short ret = 0;
	short nreg;

	in >> str;
	nreg = nregister(str);
	if (nreg == -1) return -1;
	ret |= nreg << 3;

	in >> str;
	if (str != "->") return -1;

	in >> nreg;
	ret |= (0x1F&nreg) << 6;

	in >> str;
	nreg = nregister(str);
	if (nreg == -1) return -1;
	ret |= nreg;

	return ret;
}

// bnz r3, 80
short read_bnz(istringstream &in) {
	string str;
	short ret = 0;
	short nreg;

	in >> str;
	nreg = nregister(str);
	if (nreg == -1) return -1;
	ret |= nreg;

	in >> nreg;
	if (-128 > nreg || 127 < nreg) return -1;
	ret |= (0xFF&nreg) << 3;

	return ret;
}

short read_artm(istringstream &in) {
	string str;
	short ret = 0;
	short nreg;

	in >> str;
	nreg = nregister(str);
	if (nreg == -1) return -1;
	ret |= nreg << 6;

	in >> str;
	if (str != "<-") return -1;

	in >> str;
	nreg = nregister(str);
	if (nreg == -1) return -1;
	ret |= nreg << 3;

	in >> str;
	nreg = nregister(str);
	if (nreg == -1) return -1;
	ret |= nreg;

	return ret;
}



int main (int argc, char * argv[]) {
	string str;
	short inst;
	ifstream in;
	ofstream out;

	if (argc < 3) {
		exit(1);
	}
	
	in.open(argv[1]);
	out.open(argv[2]);

	while (getline(in, str)) {
		istringstream ss(str);
		bool have_inst = true;
		inst = 0;

		ss >> str;

		if (str == "nop") ;
		else if (str == "loadb") {
			inst |= 0b00100 << 11;
			inst |= read_loads(ss);
		} else if (str == "loadw") {
			inst |= 0b00101 << 11;
			inst |= read_loads(ss);
		} else if (str == "storeb") {
			inst |= 0b00110 << 11;
			inst |= read_stores(ss);
		} else if (str == "storew") {
			inst |= 0b00111 << 11;
			inst |= read_stores(ss);
		} else if (str == "add") {
			inst |= 0b01000 << 11;
			inst |= read_artm(ss);
		} else if (str == "sub") {
			inst |= 0b01001 << 11;
			inst |= read_artm(ss);
		} else if (str == "cmp") {
			inst |= 0b01010 << 11;
			inst |= read_artm(ss);
		} else if (str == "bnz") {
			inst |= 0b011 << 13;
			inst |= read_bnz(ss);
		} else if (str == "ladd") {
			inst |= 0b100 << 13;
			inst |= read_artm(ss);
		} else {
			have_inst = false;
		}

		if (have_inst) {
			out << setfill('0') << setw(2) << hex << (inst&0xFF) << endl;
			out << setfill('0') << setw(2) << hex << ((inst>>8)&0xFF) << endl;
		}
	}
	out.close();
}
