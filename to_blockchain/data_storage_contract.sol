pragma solidity ^0.4.23;

contract data_storage_contract {

    struct Freelancer_by_project {
        uint32 id;
        string name;
        string project;
        uint32 hours_spent;
        uint32 rate;
        string currency;
    }

    Freelancer_by_project[] public freelancers;

    function push_freelancer_data(uint32 id, string name, string project, uint32 hours_spent, uint32 rate, string currency) public {
        freelancers.push(Freelancer_by_project(id, name, project, hours_spent, rate, currency));
    } 
    
    function get_freelancers_number() public constant returns(uint) {
        return freelancers.length;
    }

    function get_freelancer(uint index) public constant returns(uint32, string, string, uint32, uint32, string) {
        return (freelancers[index].id, 
                freelancers[index].name, 
                freelancers[index].project, 
                freelancers[index].hours_spent, 
                freelancers[index].rate, 
                freelancers[index].currency);
    }
   
}
