pragma solidity ^0.4.23;

contract data_storage_contract {
    
    struct Freelancer {
        string id; //freelancer id hash
        string name; //freelancer's name
        address projectAddress; //project's ethereum address
        uint128 hoursSpent; 
    }

    // struct for storing projects related information
    struct Project {  
        string id;  // project id hash
        string name; //project name
    }
    
    mapping (address => Project) projects; // bind project's address to Project type struct
    address[] public projectAccounts;
    
    mapping (address => Freelancer) freelancers; // bind freelancer's address to freelancer type struct
    address[] public freelancerAccounts;
     
    function addProject(address _address, string _id, string _name) public { 
        Project storage project = projects[_address];
        
        project.id = _id;
        project.name = _name;
        
        projectAccounts.push(_address) -1;
    }

    function getProjects() view public returns(address[]){ // get list of all project's wallets
        return projectAccounts;
    }
 
    function getProject(address _address) view public returns(string, string){ // get data for a specific project
        return (projects[_address].id, projects[_address].name);
    }
    
    function addFreelancer(address _address, 
                           string _id, 
                           string _name, 
                           address _projectAddress, 
                           uint128 _hoursSpent) public{
        Freelancer storage freelancer = freelancers[_address];
        
        freelancer.id = _id;
        freelancer.name = _name;
        freelancer.projectAddress = _projectAddress;
        freelancer.hoursSpent = _hoursSpent;
    }
    
    function getFreelancers() view public returns(address[]){ // get list of all freelancer's wallets
        return freelancerAccounts;
    }
    
    function getFreelancer(address _address) view public returns(string, string, address, uint128){ // get data for a specific freelancer
        return (freelancers[_address].id, 
                freelancers[_address].name, 
                freelancers[_address].projectAddress, 
                freelancers[_address].hoursSpent);
    }
    
    function freelancerToProject(address _address) view public returns(address){
        return freelancers[_address].projectAddress;
    }

    
    
}




