// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract TrafficManagementSystem {
    address public owner;

    enum UserType { NotRegistered, User, Police, Insurance }

    //Contains user-related, police officers, insurance company information

    struct User {
        string fullName;
        string dateOfBirth;
        string gender;
        string email;
        string phoneNumber;
        string driverLicenseNumber;
        string vehicleRegistrationNumber;
        string vehicleModel;
        UserType userType;
        uint256 points;
    }

    struct Police {
        string fullName;
        string badgeID;
        string departmentName;
        string email;
        string phoneNumber;
        string username;
        string password;
    }

    struct Insurance {
        string companyName;
        string registrationNumber;
        string email;
        string phoneNumber;
        string username;
        string password;
    }

   // mappings Ethereum addresses as keys to store user, police, and insurance data.
    mapping(address => User) public users;
    mapping(address => Police) public policeUsers;
    mapping(address => Insurance) public insuranceCompanies;
    //Storing lists of user, police, and insurance addresses
    address[] public userAddresses;
    address[] public policeAddresses;
    address[] public insuranceAddresses;

    struct Violation {
        uint256 level;
        uint256 points;
    }

    mapping(string => mapping(uint8 => Violation)) public violationPoints;

    constructor() {
        owner = msg.sender;
        // Violation points table
        violationPoints['Speeding'][1] = Violation(1, 3);
        violationPoints['Speeding'][2] = Violation(2, 4);
        violationPoints['Speeding'][3] = Violation(3, 6);
        violationPoints['Speeding'][4] = Violation(4, 8);
        violationPoints['Speeding'][5] = Violation(5, 11);

        violationPoints['Reckless driving'][1] = Violation(1, 4);

        violationPoints['Running red light'][1] = Violation(1, 2);

        violationPoints['Driving without a valid license'][1] = Violation(1, 5);
        violationPoints['Driving without insurance'][1] = Violation(1, 6);
        violationPoints['Illegal parking'][1] = Violation(1, 1);
        violationPoints['Driving under the influence'][1] = Violation(1, 10);
        violationPoints['Driving without seatbelt'][1] = Violation(1, 2);
        violationPoints['Using a mobile phone while driving'][1] = Violation(1, 3);
        violationPoints['Driving with expired registration'][1] = Violation(1, 4);
        violationPoints['Fleeing the scene of an accident'][1] = Violation(1, 8);
        violationPoints['Running a stop sign'][1] = Violation(1, 2);
        violationPoints['Driving in a bike lane'][1] = Violation(1, 1);
        violationPoints['Driving the wrong way'][1] = Violation(1, 3);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this operation.");
        _;
    }

    modifier requireRegistration() {
        require(users[msg.sender].userType != UserType.NotRegistered, "User must be registered.");
        _;
    }

    // functions allowing users to register as regular users, police officers, or insurance companies.

    function registerUser(
        string memory _fullName,
        string memory _dateOfBirth,
        string memory _gender,
        string memory _email,
        string memory _phoneNumber,
        string memory _driverLicenseNumber,
        string memory _vehicleRegistrationNumber,
        string memory _vehicleModel
        ) public {
        require(users[msg.sender].userType == UserType.NotRegistered, "User already registered.");
        require(bytes(_vehicleRegistrationNumber).length > 0, "Vehicle registration number cannot be empty.");
        require(!isNumberPlateTaken(_vehicleRegistrationNumber), "Number plate is already registered by another user.");

        // Registering a new user
        users[msg.sender] = User({
            fullName: _fullName,
            dateOfBirth: _dateOfBirth,
            gender: _gender,
            email: _email,
            phoneNumber: _phoneNumber,
            driverLicenseNumber: _driverLicenseNumber,
            vehicleRegistrationNumber: _vehicleRegistrationNumber,
            vehicleModel: _vehicleModel,
            userType: UserType.User,
            points: 0
        });

        // adds the user's Ethereum address (msg.sender) to the userAddresses array
        userAddresses.push(msg.sender);
    }

    function registerPolice(string memory _fullName, string memory _badgeID, string memory _departmentName, string memory _email, string memory _phoneNumber, string memory _username, string memory _password) public {
        require(users[msg.sender].userType == UserType.NotRegistered, "User already registered.");

        // Creation of new Police struct and populate the information
        Police memory newPolice;
        newPolice.fullName = _fullName;
        newPolice.badgeID = _badgeID;
        newPolice.departmentName = _departmentName;
        newPolice.email = _email;
        newPolice.phoneNumber = _phoneNumber;
        newPolice.username = _username;
        newPolice.password = _password;

        policeUsers[msg.sender] = newPolice;
        policeAddresses.push(msg.sender);
        users[msg.sender].userType = UserType.Police;
    }

    function registerInsurance(string memory _companyName, string memory _registrationNumber, string memory _email, string memory _phoneNumber, string memory _username, string memory _password) public {
        require(users[msg.sender].userType == UserType.NotRegistered, "User already registered.");

        // Creation of new Insurance struct and populate the information
        Insurance memory newInsurance;
        newInsurance.companyName = _companyName;
        newInsurance.registrationNumber = _registrationNumber;
        newInsurance.email = _email;
        newInsurance.phoneNumber = _phoneNumber;
        newInsurance.username = _username;
        newInsurance.password = _password;

        insuranceCompanies[msg.sender] = newInsurance;
        insuranceAddresses.push(msg.sender);
        users[msg.sender].userType = UserType.Insurance;
    }

    function addPoints(string memory _numberPlate, string memory _violation, uint8 _level) public requireRegistration {
        require(users[msg.sender].userType == UserType.Police, "Only police can add points.");
        require(bytes(_numberPlate).length > 0, "Vehicle number plate cannot be empty.");
        require(bytes(_violation).length > 0, "Violation type cannot be empty.");
        require(_level >= 1 && _level <= 5, "Invalid violation level.");

        address userAddress = findUserByNumberPlate(_numberPlate);
        if (userAddress != address(0)) {
            uint256 pointsToAdd = violationPoints[_violation][_level].points;
            users[userAddress].points += pointsToAdd;
        }
    }

    function getPoints() public view requireRegistration returns (uint256) {
        return users[msg.sender].points;
    }

    function getUserType() public view requireRegistration returns (uint8) {
        return uint8(users[msg.sender].userType);
    }

    // Function allows insurance companies to view the points of a specific user based on the user's address.
    function viewUserPoints(address _userAddress) public view requireRegistration returns (uint256) {
        require(users[msg.sender].userType == UserType.Insurance, "Only Insurance can view points.");
        return users[_userAddress].points;
    }

    //function allows users and police officers to retrieve user data based on a vehicle's number plate
    function getUserDataByNumberPlate(string memory _numberPlate) public view returns (UserType, uint256, string memory, string memory, string memory) {
        require(bytes(_numberPlate).length > 0, "Vehicle number plate cannot be empty.");

        address userAddress = findUserByNumberPlate(_numberPlate);
        if (userAddress != address(0)) {
            if (msg.sender == userAddress || users[msg.sender].userType == UserType.Police) {
                User memory userData = users[userAddress];
                return (userData.userType, userData.points, userData.fullName, userData.vehicleModel, userData.vehicleRegistrationNumber);
            }
        }
        revert("Number plate not found in the records or unauthorized access.");
    }


    // to check if a vehicle registration number is already registered
    function isNumberPlateTaken(string memory _numberPlate) internal view returns (bool) {
        for (uint i = 0; i < userAddresses.length; i++) {
            address userAddress = userAddresses[i];
            if (keccak256(abi.encodePacked(users[userAddress].vehicleRegistrationNumber)) == keccak256(abi.encodePacked(_numberPlate))) {
                return true;
            }
        }
        return false;
    }
    // to find a user's address by their vehicle registration number.
    function findUserByNumberPlate(string memory _numberPlate) internal view returns (address) {
        for (uint i = 0; i < userAddresses.length; i++) {
            address userAddress = userAddresses[i];
            if (keccak256(abi.encodePacked(users[userAddress].vehicleRegistrationNumber)) == keccak256(abi.encodePacked(_numberPlate))) {
                return userAddress;
            }
        }
        return address(0);
    }

    function calculateInsurancePremiumPerMonth(
        string memory _numberPlate,
        uint256 _vehicleValue,     // Car value
        uint256 _coverageAmount    // Coverage amount
    ) public view requireRegistration returns (uint256) {
        require(users[msg.sender].userType == UserType.Insurance, "Only Insurance can calculate premiums.");

        address userAddress = findUserByNumberPlate(_numberPlate);
        require(userAddress != address(0), "Driver not found for the provided vehicle number plate.");

        User memory userData = users[userAddress];

        // Retrieving penalty points from the user's account
        uint256 penaltyPoints = userData.points; 
        
        // Calculation of premium per month based on car value, coverage amount, and retrieved penalty points
        uint256 premium = 0;
        
        uint256 carValueFactor = (_vehicleValue / 1000) * 100; 
        
        uint256 coverageFactor = (_coverageAmount / 10000) * 50; 
        
        uint256 pointsFactor = penaltyPoints * 1000; 
        
        premium = (carValueFactor + coverageFactor + pointsFactor) / 12;
        
        return premium;
    }

}