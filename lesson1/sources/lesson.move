module lesson_addr::lessonlist {
    use aptos_framework::event;
    use aptos_framework::account;
    use std::string::String;
    use aptos_std::table::{Self,Table};
    use aptos_std::signer;

    #[test_only]
    use std::string;

    // Errors
    const E_NOT_INITIALIZED: u64 = 1;
    const ESTUDENT_DOESNT_EXIST: u64 = 2;
    const ESTUDENT_IS_COMPLETED: u64 = 3;

    struct StudentList has key{
        students: Table<u64, Student>,
        set_student_event: event::EventHandle<Student>,
        student_counter:u64
    }
    struct Student has store, drop, copy{
        student_id: u64,
        address: address,
        name: String,
        age: u64,
        dept: String,
        year: u64,
        sem: u64,
    }

    public entry fun create_list(account: &signer){
        let student_holder = StudentList{
            students: table::new(),
            set_student_event: account::new_event_handle<Student>(account),
            student_counter: 0
        };
        move_to(account, student_holder);
    }
 
    public entry fun create_student(account: &signer, name: String, age: u64, dept: String, year: u64, sem: u64) acquires StudentList{
        let signer_address = signer::address_of(account);
        assert!(exists<StudentList>(signer_address), E_NOT_INITIALIZED);
        let student_list = borrow_global_mut<StudentList>(signer_address);
        let counter = student_list.student_counter + 1;

        // Creates a new Student

        let new_student = Student {
            student_id: counter,
            address: signer_address,
            name,
            age,
            dept,
            year,
            sem
        };

        table::upsert(&mut student_list.students, counter, new_student);
        student_list.student_counter = counter;
        event::emit_event<Student>(
            &mut borrow_global_mut<StudentList>(signer_address).set_student_event,
            new_student,
        );
    }

    #[test(admin = @0x123)]
    public entry fun test_flow(admin: signer) acquires StudentList{
        account::create_account_for_test(signer::address_of(&admin));
        create_list(&admin);
        create_student(&admin, string::utf8(b"Barry"), 21, string::utf8(b"CSE"), 3, 6);
        let student_count = event::counter(&borrow_global<StudentList>(signer::address_of(&admin)).set_student_event);
        assert!(student_count == 1,4);
        let student_list = borrow_global<StudentList>(signer::address_of(&admin));
        assert!(student_list.student_counter == 1, 5);
        let student_record = table::borrow(&student_list.students, student_list.student_counter);
        assert!(student_record.student_id == 1,6);
        assert!(student_record.name ==string::utf8(b"Barry"), 7);
        assert!(student_record.age == 21, 8);       
        assert!(student_record.dept ==string::utf8(b"CSE"), 9);
        assert!(student_record.year == 3, 10);
        assert!(student_record.sem == 6, 11);
    }
    
}