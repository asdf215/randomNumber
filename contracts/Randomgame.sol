//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 < 0.9.0;

contract Random {
    event paidAddress(address indexed sender, uint256 payment);
    event winnerAddress(address indexed winner);

    modifier onlyOwner() { //배포자만 실행 가능
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
    mapping (uint256 => mapping(address => bool)) public paidAddressList; //주소 중복 인지 확인하여 중복 참여 방지 
    //true일때는 이미 참여했기 때문에 참여할 수 없고 false일때만 참여가능
    //첫번째 매핑값은 게임 회차
    //우승자 등장시 게임 회차 바뀜
    address public owner;//랜덤 게임을 배포한 주소
    string private key1; //난수 발생 요소
    uint private key2; //난수 발생 요소
    uint private winnerNumber = 0; //우승자

    uint public round = 1; //라운드 초기화시에 PaidAddressList 초기화 -> 재참여
    uint public playNumber = 0; //몇 번째 참여자 //playNumber 와 winnerNumber가 같을 때 그 참가자가 우승

    constructor(string memory _key1, uint _key2){
        owner = msg.sender;
        key1 = _key1;
        key2 = _key2;
        winnerNumber = randomNumber();
    }

    receive() external payable{
        require(msg.value == 10**16, "Must be 0.01 ether.");
        require(paidAddressList[round][msg.sender] == false, "must be the first time.");
        paidAddressList[round][msg.sender] = true;
        ++playNumber;
        if(playNumber == winnerNumber){
            (bool success,) = msg.sender.call{value: address(this).balance}("");//랜덤 smart contract에 누적된 잔액을 msg.sender (우승자)에게 전달
            require(success, "Failed");
            playNumber = 0; //초기화
            ++round; //라운드 1증가 시켜서 다음 회차로 re-rounding
            winnerNumber = randomNumber();
            emit winnerAddress(msg.sender);//우승자
        }else{
            emit paidAddress(msg.sender, msg.value);//게임 참여자
        }
    }

    function randomNumber() private view returns(uint){
        uint num = uint(keccak256(abi.encode(key1))) + key2 + (block.timestamp) + (block.number);
        return (num - ((num/10)*10)) + 1; //1부터 10까지 수를 무작위로 생성
    }

    function setSecretKey(string memory _key1, uint _key2) public onlyOwner(){
        key1 = _key1;
        key2 = _key2;
    }
    
    function getSecretKey() public view onlyOwner() returns(string memory, uint){
        return(key1, key2);
    }

    function getWinnerNumber() public view onlyOwner() returns(uint256){
        return winnerNumber;
    }

    function getRound() public view returns(uint256){
        return round;
    }

    function getbalance() public view returns(uint256){
        return address(this).balance;
    }
}

