// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Permit {
    // 관리자 주소
    address private owner;

    // 허용자 목록
    mapping(address => bool) private allower; // 매핑을 통해, allow[A지갑] = true이면 허용됨을 의미합니다.
    address[] private allowerList; // allower의 리스트를 배열로 담아내는 변수

    // 관리자 여부 확인
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner"); // 해당 기능을 호출하는 사람이 관리자가 아닐 때를 의미합니다.
        _;
    }

    // 허용자 여부 확인
    modifier isAllower() {
        require(allower[msg.sender] == true, "Caller is not allower"); // 해당 기능을 호출하는 사람이 관리자가 아닐 때를 의미합니다.
        _;
    }

    // 생성자
    constructor() {
        owner = msg.sender; // 관리자를 컨트랙트 만드는(발행하는) 사람의 지갑을 자동적으로 관리자로 세팅
        allower[msg.sender] = true; // 관리자를 허용자로 설정
        allowerList.push(msg.sender); // 허용자 배열에 관리자를 추가해줌
    }

    // 관리자 변경
    function changeOwner(address _owner) public isOwner {
        require(_owner != address(0), "Address is zero"); // 관리자를 없앨 수 없음을 의미합니다.
        require(_owner != owner, "Address is already owner"); // 바꾸려고 하는 새로운 관리자 지갑이 기존 관리자와 동일함을 의미합니다.

        owner = _owner; // 관리자를 새로운 관리자로 설정
    }

    // 새로운 허용자 추가
    function newAllower(address _new) public isOwner {
        require(allower[_new] == false, "Address is already allower");

        allowerList.push(_new); // 허용자 배열에 새로운 유저를 추가해줌
        allower[_new] = true; // 새로운 유저를 매핑해서 권한을 true로 설정해줌
    }

    // 허용자 삭제
    function deleteAllower(address _delete) public isOwner {
        require(allower[_delete] == true, "Address is not allower");

        delete allower[_delete]; // 기존에 매핑된 유저의 true값을 없애 권한을 삭제함(false 처리)

        for (uint i = 0; i < allowerList.length; i++) { // 허용자 리스트에 권한을 지울 유저의 값을 지워줌
            if (allowerList[i] == _delete) {
                allowerList[i] = allowerList[allowerList.length - 1];
                allowerList.pop();
                break;
            }
        }
    }

    // 관리자 주소 조회
    function getOwner() isAllower external view returns (address) {
        return owner;
    }

    // 허용자 목록 조회
    function getAllowers() isAllower external view returns (address[] memory) {
        return allowerList;
    }
}

contract priv is Permit {
    // 파일 정보 구조체
    struct File {
        string fileId; // 파일의 아이디(해쉬)를 기재
        string pw; // 파일에 걸려있는 암호를 입력
        address owner; // 파일을 블록체인에 올리는 유저의 지갑주소를 자동 설정
        uint256 timeStamp; // 파일을 블록체인에 올려진 시간을 자동 설정
        Update[] update; // 업데이트 한 유저의 기록을 누적하여 등록
    }

    // 업데이트 정보 구조체
    struct Update {
        string fileId;
        string pw;
        address updater;
        uint256 timeStamp;
    }

    // 파일 역사 구조체
    struct History {
        address viewer;
        uint256 timeStamp;
    }

    // 파일 이름 목록
    string[] private file;

    // 파일 정보 매핑
    mapping(string => File) private files;

    // 파일 역사 매핑
    mapping(string => History[]) private fileHistory;

    // 파일 추가
    function setFile(string memory _name, string memory _fileId, string memory _pw) public isAllower returns (bool) {
        require(files[_name].owner == address(0), "File is already exist");

        file.push(_name);
        files[_name].fileId = _fileId;
        files[_name].pw = _pw;
        files[_name].owner = msg.sender;
        files[_name].timeStamp = block.timestamp;

        return true;
    }

    // 파일 삭제
    function deleteFile(string memory _name) public isAllower returns (bool) {
        require(files[_name].owner == msg.sender, "Caller is not owner");
        delete files[_name];

        for (uint i = 0; i < file.length; i++) {
            if (keccak256(abi.encodePacked(file[i])) == keccak256(abi.encodePacked(_name))) {
                file[i] = file[file.length - 1];
                file.pop();
                break;
            }
        }

        return true;
    }

    // 파일 업데이트
    function updateFile(string memory _name, string memory _fileId, string memory _pw) public isAllower returns (bool) {
        files[_name].update.push(Update(_fileId, _pw, msg.sender, block.timestamp));
        return true;
    }

    // 파일 정보 조회
    function getFile(string memory _name) public isAllower returns (string memory fileId, string memory pw, address owner, Update[] memory update, uint256 timeStamp) {
        fileHistory[_name].push(History(msg.sender, block.timestamp));
        return (files[_name].fileId, files[_name].pw, files[_name].owner, files[_name].update, files[_name].timeStamp);
    }

    // 파일 목록 조회
    function getFileList() public isAllower view returns (string[] memory) {
        return file;
    }

    // 파일 역사 조회
    function getFileHistory(string memory _name) public isAllower view returns (History[] memory) {
        return fileHistory[_name];
    }
}