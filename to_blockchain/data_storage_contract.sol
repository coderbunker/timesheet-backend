pragma solidity ^0.4.23;

contract data_storage_contract {
    
    struct Freelancer {
        bytes32 id; //freelancer id hash
        bytes32 name; //freelancer's name
        address projectAdress; //project's ethereum address
        uint32 hoursSpent; 
        uint32 tasksCompleted; 
    }

    // struct for storing projects related information
    struct Project {  
        bytes32 id;  // project id hash
        bytes32 name; //project name
        //TODO: add list of freelancers 
        address[] freelancers; //list of freelancers wallets
    }
    
    mapping (address => Project) projects; // bind project's address to Project type struct
    address[] public projectAccs;
    
    mapping (address => Freelancer) freelancers; // bind freelancer's address to freelancer type struct
    address[] public freelancerAccs;
     
    function addProject(address _address, bytes32 _id, bytes32 _name) public { // TODO: add msg.sender
        Project storage project = projects[_address];
        
        project.id = _id;
        project.name = _name;
        
        projectAccs.push(_address) -1;
    }

    function getProjects() view public returns(address[]){ // get list of all project's wallets
        return projectAccs;
    }
 
    function getProject(address _address) view public returns(bytes32, bytes32){ // get data for a specific project
        return (projects[_address].id, projects[_address].name);
    }
    
    function addFreelancer(address _address, 
                           bytes32 _id, 
                           bytes32 _name, 
                           address _projectAdress, 
                           uint32 _hoursSpent, 
                           uint32 _tasksCompleted) public{
        Freelancer storage freelancer = freelancers[_address];
        
        freelancer.id = _id;
        freelancer.name = _name;
        freelancer.projectAdress = _projectAdress;
        freelancer.hoursSpent = _hoursSpent;
        freelancer.tasksCompleted = _tasksCompleted;
    }
    
    function getFreelancers() view public returns(address[]){ // get list of all freelancer's wallets
        return freelancerAccs;
    }
    
    function getFreelancer(address _address) view public returns(bytes32, bytes32,address, uint32, uint32){ // get data for a spiciefic freelancer
        return (freelancers[_address].id, 
                freelancers[_address].name, 
                freelancers[_address].projectAdress, 
                freelancers[_address].hoursSpent, 
                freelancers[_address].tasksCompleted);
    }
    
    function freelancerToProject(address _address) view public returns(address){
        return freelancers[_address].projectAdress;
    }

    
    
}
