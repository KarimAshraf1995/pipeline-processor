#include <iostream>
#include <fstream>
#include <string>
#include <unordered_map>
#include <vector>
#include <algorithm>
#include <bitset>
#include<regex>
#include <sstream>
using namespace std;

//remove comments
//handle end of line spaces in input & possibly output

struct Instr_Props
{
	string bits;
	int opType;
};

string getRegBits(string reg)
{
	return bitset<3>(reg[1]-'0').to_string();
}

int main()
{
	// Reading the mapping of instructions to bits
	ifstream instrToBits;
	instrToBits.open("InstrToBits.txt");
	unordered_map<string, Instr_Props> instr_bits;
	string instruction, bits;
	int opType;
	while (instrToBits >> instruction)
	{
		instrToBits >> bits;
		instrToBits >> opType;
		instr_bits.insert({ instruction,Instr_Props{bits,opType} });
	}
	instrToBits.close();

	ifstream inputFile;
	inputFile.open("assembly.asm", ios::in);
	//convert string to stream & remove semicolons with regex

	ofstream InstructionFile;
	InstructionFile.open("instructions.mem", ios::out);
	ofstream DataFile;
	DataFile.open("data.mem", ios::out);
	if (!inputFile) {
		cerr << "Unable to open file assembly.txt";
		exit(1);   // call system to stop
	}
	if (!InstructionFile) {
		cerr << "Unable to open file instructions.txt";
		exit(1);   // call system to stop
	}
	if (!DataFile) {
		cerr << "Unable to open file instructions.txt";
		exit(1);   // call system to stop
	}

	//Data Part
	string data;
	int count = 0;
	while (getline(inputFile,data))
	{
		if (data == "")
			continue;
		data = regex_replace(data, regex(";[^~]*$"), "");
		if (data.length() < 1)
			continue;
		if (data[0]<'0' || data[0]>'9')
			break;
		data = regex_replace(data, regex(" "), "");
		DataFile << bitset<16>(stoi(data)).to_string() << " ";
		count++;
	}
	for (int i = count; i < 256; i++)
		DataFile << bitset<16>(0).to_string()<<" ";

	//Instruction Part
	string op1, op2;
	instruction = "";
	string line = "";
	count = 0;
	while (line=="" || getline(inputFile, line))
	{
		
		if (line == "")
			line = data;
		else
		{
			if (line == "")
				continue;
			line = regex_replace(line, regex(";[^~]*$"), "");
		}
		stringstream ss(line);
		instruction = line.substr(0,line.find(" ")); 
		string operands = line.substr(line.find(" ")+1, line.length() - line.find(" ")-1); 

		if (instruction[0] == '.')
		{
			int dstInstr = stoi(instruction.substr(1, instruction.length() - 1));
			while(count++<dstInstr)
				InstructionFile << "0000000000000000" << " ";
		}
		else
		{
			//int bits[32];
			//memset(bits, 0, sizeof(bits));
			transform(instruction.begin(), instruction.end(), instruction.begin(), toupper);
			Instr_Props instr_prop = instr_bits[instruction];
			//vector<int> bits = getdigits(instr_prop.bits);
			string bits = instr_prop.bits;
			//remove_if(operands.begin(), operands.end(), isspace);
			operands = regex_replace(operands,regex(";[^~]*$"),"");
			operands = regex_replace(operands,regex(" "),"");


			//Parsing Operands (assuming no semi-colon at end & new line char)
			string delimiter = ",";
			size_t pos = 0;
			std::string token;
			string op1 = "", imm = "", op2 = "", ea = "";
			bool takeToken = false;
			//while ((pos = operands.find(delimiter)) != std::string::npos) {
			while(true){
				if ((pos = operands.find(delimiter)) != std::string::npos)
					takeToken = true;
				else
				{
					takeToken = false;
					token = operands;
				}
				token = operands.substr(0, pos);
				if (op1 == "")
					op1 = token;
				else if (op2 == "")
				{
					op2 = token;
					if (instr_prop.opType == 5) //assuming imm 16 bits
						imm = bitset<16>(stoi(op2)).to_string();
					else if (instr_prop.opType == 6)
						ea = bitset<9>(stoi(op2)).to_string();
				}
				else
				{
					if (instr_prop.opType == 4)
					{
						imm = (stoi(op2) < 32) ? op2 : "0";
						imm = bitset<5>(stoi(imm)).to_string();
						op2 = token;
					}
				}
				if (!takeToken)
					break;
				operands.erase(0, pos + delimiter.length());
			}

			if(op1!="")
				op1 = getRegBits(op1);
			if(op2!="")
				op2 = getRegBits(op2);

			string upper15;
			switch (instr_prop.opType)
			{
			case 1: //NULL Type 
				InstructionFile << "0000000000000" + bits << " ";
				break;
			case 2: //R-Type
				InstructionFile << "001" + op1 + op2 + "0000" + bits << " ";
				break;
			case 3: //A-Type
				InstructionFile << "010" + op1 + op1 + "000" + bits << " ";
				break;
			case 4: //S-Type
				InstructionFile << "011" + op1 + op2 + imm + "0" + bits << " ";
				break;
			case 5: //I-Type
				upper15 = "100" + op1 + op1 + "000000";
				if ((upper15 + "1") == imm)
					InstructionFile << upper15 + "0" << " ";
				else
					InstructionFile << upper15 + "1" << " ";
				InstructionFile << imm << " ";
				break;
			case 6: //X-Type
				InstructionFile << "101" + op1 + ea + bits << " ";
				break;
			case 7: //J-Type
				InstructionFile << "110" + op1 + "000000" + bits << " ";
				break;
			}
			count++;
		}
	}
	for (int i = count; i < 256; i++)
		InstructionFile << bitset<16>(0).to_string() << " ";
	inputFile.close();
	InstructionFile.close();
	DataFile.close();
	return 0;
}