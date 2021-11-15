// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.9 <0.9.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";
import "./SafeMath.sol";

contract Disney {
    using SafeMath for uint256;
    // --------------------- Declaracion iniciales -------------------------
    
    ERC20Basic private token;
    address payable private owner;
    
    constructor () {
        token = new ERC20Basic(100);
        owner = payable(msg.sender);
    }
    
    struct cliente {
        uint tokens_comprados;
        string[] atracciones_disfrutadas;
    }
    
    mapping(address => cliente) public Clientes;
    
    // ---------------------- Gestion de tokens -----------------------------
    
    function PrecioTokens(uint _numTokens) internal pure returns (uint) {
        return uint(1 ether * _numTokens);
    }
    
    function ComprarTokens(uint _numTokens) public payable {
        uint coste = PrecioTokens(_numTokens);
        // Verificamos que con estos ethers puede pagar los tokens que quiere comprar
        require(msg.value >= coste, 'Compra menos tokens o paga con mas ethers');
        
        // Verificamos que el contrato tiene los tokens suficientes para vender
        uint balance = balanceOf();
        require(_numTokens <= balance, 'Compra un numero de tokens menor');
        
        uint returnValue = msg.value.sub(coste);
        payable(msg.sender).transfer(returnValue);
        
        token.transfer(msg.sender, _numTokens);
        
        Clientes[msg.sender].tokens_comprados = Clientes[msg.sender].tokens_comprados.add(_numTokens);
    }
    
    function balanceOf() public view returns (uint) {
        return token.balanceOf(address(this));
    }
    
    function MisTokens() public view returns (uint) {
        return token.balanceOf(msg.sender);
    }
    
    function GeneraTokens(uint _numTokens) public Unicamente(msg.sender) {
        token.increaseTotalSupply(_numTokens);    
    } 
    
    modifier Unicamente(address direccion) {
        require(direccion == owner, 'No tienes derechos para ejecutar esta funcion');
        _;
    }
    
    // ----------------------------- Destion de Disney ----------------------------------
    
    event disfruta_atraccion(address, string, uint);
    event nueva_atraccion(string, uint);
    event baja_atraccion(string);
    
    enum STATE { Active, Inactive }
    
    struct atraccion {
        string nombre_atraccion;
        uint precio_atraccion;
        STATE estado_atraccion;
    }
    
    mapping(string => atraccion) public MappingAtracciones;
    string [] Atracciones;
    mapping(address => string[]) HistorialAtracciones;
    
    function NuevaAtraccion(string memory _nombre, uint _precio) public Unicamente(msg.sender) {
        MappingAtracciones[_nombre] = atraccion(_nombre, _precio, STATE.Active);
        Atracciones.push(_nombre);
        emit nueva_atraccion(_nombre, _precio);
    }
    
    function BajaAtraccion(string memory _nombre) public Unicamente(msg.sender) {
        require(MappingAtracciones[_nombre].estado_atraccion == STATE.Active, 'Atraccion no existe o ya esta de baja');
        MappingAtracciones[_nombre].estado_atraccion = STATE.Inactive;
        emit baja_atraccion(_nombre);
    }
    
    function AtraccionesDisponibles() public view returns (string [] memory) {
        return Atracciones;
    }
    
    function SubirseAtraccion(string memory _nombreAtraccion) public payable {
        uint tokensAtraccion = MappingAtracciones[_nombreAtraccion].precio_atraccion;
        require(MappingAtracciones[_nombreAtraccion].estado_atraccion == STATE.Active, 'Atraccion no existe o no esta disponible');
        require(tokensAtraccion <= MisTokens(), 'Necesitas tener mas tokens para poder subirse a estra atraccion');
        address direccionCliente = msg.sender;
        token.transferFrom(direccionCliente, address(this), tokensAtraccion);
        HistorialAtracciones[direccionCliente].push(_nombreAtraccion);
        emit disfruta_atraccion(direccionCliente, _nombreAtraccion, tokensAtraccion);
    }
    
    function Historial() public view returns (string [] memory) {
        return HistorialAtracciones[msg.sender];
    }
    
    function DevolverTokens(uint _numTokens) public payable {
        require(_numTokens > 0, 'Numero de tokens a devolver tiene que ser mayor de 0');
        require(_numTokens <= MisTokens(), 'Solicita menos tokens a devolver');
        token.transferFrom(msg.sender, address(token), _numTokens);
        payable(msg.sender).transfer(PrecioTokens(_numTokens));
    }
    
    // --------------------------- Gestion de compra de comida ----------------------------------
    
    event ComidaComprada(address,string,uint);
    event NuevaComida(string,uint,STATE);
    event BajaComida(string);
    
    struct comida {
        string nombre_comida;
        uint precio_comida;
        STATE estado_comida;
    }
    
    string [] Comidas;
    mapping(string => comida) public MappingComida;
    mapping(address => string[]) HistorialComida;
    
    function DarAltaComida(string memory _nombre, uint _precio) public Unicamente(msg.sender) {
        Comidas.push(_nombre);
        MappingComida[_nombre] = comida(_nombre, _precio, STATE.Active);
        emit NuevaComida(_nombre, _precio, STATE.Active);
    }
    
    function DarBajaComida(string memory _nombre) public Unicamente(msg.sender) {
        MappingComida[_nombre].estado_comida = STATE.Inactive;
    }
    
    function ComidasDisponibles() public view returns (string [] memory){
        return Comidas;
    }
    
    function ComprarComida(string memory _nombre) public {
        uint numTokens = MappingComida[_nombre].precio_comida;
        require(numTokens <= MisTokens(), 'No tienes suficientes tokens para la compra');
        require(MappingComida[_nombre].estado_comida == STATE.Active, 'El menu no esta disponible');
        token.transferFrom(msg.sender, address(this), numTokens);
        HistorialComida[msg.sender].push(_nombre);
        emit ComidaComprada(msg.sender, _nombre, numTokens);
    }
    
    function HistorialComidas() public view returns (string [] memory) {
        return HistorialComida[msg.sender];
    }
}