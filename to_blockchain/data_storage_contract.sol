pragma solidity ^0.4.23;

contract data_storage_contract {
    
    struct Freelancer {
        string id; //freelancer id hash
        string name; //freelancer's name
        address projectAdress; //project's ethereum address
        uint32 hoursSpent; 
        uint32 tasksCompleted; 
    }

    // struct for storing projects related information
    struct Project {  
        string id;  // project id hash
        string name; //project name
    }
    
    mapping (address => Project) projects; // bind project's address to Project type struct
    address[] public projectAccs;
    
    mapping (address => Freelancer) freelancers; // bind freelancer's address to freelancer type struct
    address[] public freelancerAccs;
     
    function addProject(address _address, string _id, string _name) public { 
        Project storage project = projects[_address];
        
        project.id = _id;
        project.name = _name;
        
        projectAccs.push(_address) -1;
    }

    function getProjects() view public returns(address[]){ // get list of all project's wallets
        return projectAccs;
    }
 
    function getProject(address _address) view public returns(string, string){ // get data for a specific project
        return (projects[_address].id, projects[_address].name);
    }
    
    function addFreelancer(address _address, 
                           string _id, 
                           string _name, 
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
    
    function getFreelancer(address _address) view public returns(string, string, address, uint32, uint32){ // get data for a spiciefic freelancer
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
