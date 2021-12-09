// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Comn.sol";
import "./INFT.sol";
import "./IPet.sol";
import "./IEgg.sol";
import "./ISale.sol";
import "./ICoin.sol";

/**
 * @title karastart's NFT pet
 */
contract PetNFT is Comn, IPet {
    // pet descr
    struct Pet {
        PetGene body;
        PetGene ear;
        PetGene eye;
        PetGene horn;
        PetGene mouth;
        PetGene notum;
        PetGene tail;
        uint8 breed;
        uint8 elimit;  // evolve limit
        uint8 blimit; // breed limit
        uint32 htime; // new time
        uint128 eggid; // from egg
    }

    enum PetBody {
        None,
        Body,
        Ear,
        Eye,
        Horn,
        Mouth,
        Notum,
        Tail
    }

    struct PetGene {
        // PetKind kind;
        uint8 appea;
        uint8 hidden;
        uint8 deity; // 0-100
        uint16 grade;
    }

    struct GeneRate {
        PetBody body;
        uint8 rate;
        uint8 deity;
    }
    
    mapping(uint256 => Pet) internal _pets;
    mapping(uint256 => uint256) internal _evolveNums;

    event Evolve(uint256 indexed id, Pet pet);
    
    /**
     * @dev lay a pet from egg
     */
    function layPet(
        uint256 eggid,
        uint256 fatherID,
        uint256 motherID
    ) public virtual override onlyEggCter returns (uint256) {
        INFT nft = INFT(reg.nftAddr());
        address account = nft.ownerOf(eggid);
        Pet memory father = _pets[fatherID];
        Pet memory mother = _pets[motherID];
        require(
            account != address(0) && father.htime > 0 && mother.htime > 0
        );
        uint256 id = nft.mintPet(account);
        _pets[id] = Pet({
            body: _newGene(PetBody.Body, father.body, mother.body),
            ear: _newGene(PetBody.Ear, father.ear, mother.ear),
            eye: _newGene(PetBody.Eye, father.eye, mother.eye),
            horn: _newGene(PetBody.Horn, father.horn, mother.horn),
            mouth: _newGene(PetBody.Mouth, father.mouth, mother.mouth),
            notum: _newGene(PetBody.Notum, father.notum, mother.notum),
            tail: _newGene(PetBody.Tail, father.tail, mother.tail),
            breed: 0,
            elimit: (father.elimit + mother.elimit) / 2,
            blimit: (father.blimit + mother.blimit) / 2,
            htime: uint32(block.timestamp),
            eggid: uint128(eggid)
        });
        return id;
    }

    /**
     * @dev generate a pet by sets for a account
     */
    function newPet(address account, uint256[] memory sets)
        public
        virtual
        override
        onlyNFTCters
        returns (uint256)
    {
        return _newPet(account, sets);
    }

    /**
     * @dev generate a pet by sets for a account
     */
    function _newPet(address account, uint256[] memory sets) internal virtual returns (uint256) {
        require(sets.length >= 9);
        uint256 evolveLimit = rand(sets[2] - sets[1], 1) + sets[1];
        uint256 breedLimit = rand(sets[4] - sets[3], 2) + sets[3];
        uint256 deityNum = rand(sets[6] - sets[5], 3) + sets[5];

        // rand gene body
        uint256[4] memory deity = [uint256(0), 0, 0, 0];
        uint256 i = rand(deity.length - deityNum, 4);
        uint256 e = i + deityNum;
        for (i; i < e; i++) {
            deity[i] = rand(sets[8] - sets[7], i) + sets[7];
        }
        return _newPet(account, evolveLimit, breedLimit, deity);
    }

    /**
     * @dev generate a pet by grade for a account
     */
    function _newPet(
        address account,
        uint256 evolveLimit,
        uint256 breedLimit,
        uint256[4] memory deity
    ) internal virtual returns (uint256) {
        uint256 id = INFT(reg.nftAddr()).mintPet(account);
        _pets[id] = Pet({
            body: _randGene(PetBody.Body, 0, id),
            ear: _randGene(PetBody.Ear, 0, id),
            eye: _randGene(PetBody.Eye, 0, id),
            horn: _randGene(PetBody.Horn, deity[0], id),
            mouth: _randGene(PetBody.Mouth, deity[1], id),
            notum: _randGene(PetBody.Notum, deity[2], id),
            tail: _randGene(PetBody.Tail, deity[3], id),
            breed: 0,
            elimit: uint8(evolveLimit),
            blimit: uint8(breedLimit),
            htime: uint32(block.timestamp),
            eggid: uint128(0)
        });
        return id;
    }

    /**
     * @dev get a pet information
     */
    function info(uint256 id) public view virtual returns (Pet memory) {
        return _pets[id];
    }

    /**
     * @dev two pet can generate a egg
     */
    function layCan(uint256 fatherID, uint256 motherID)
        public
        view
        virtual
        returns (bool)
    {
        require(fatherID != motherID);
        Pet memory father = _pets[fatherID];
        Pet memory mother = _pets[motherID];

        // exists
        require(father.htime > 0 && mother.htime > 0);

        // breed times
        require(
            father.breed < father.blimit && mother.breed < mother.blimit
        );

        // 
        INFT nft = INFT(reg.nftAddr());
        require(
            nft.ownerOf(fatherID) == msg.sender &&  nft.ownerOf(motherID) == msg.sender
        );

        return true;
    }

    /**
     * @dev get the UMY needed to lay eggs
     */
    function layCoin(uint256 fatherID, uint256 motherID)
        public
        view
        virtual
        returns (uint256)
    {
        return
            (reg.breedFee(_pets[fatherID].breed) +
                reg.breedFee(_pets[motherID].breed)) *
            reg.umyPrice() * (10 ** ICoin(reg.umyAddr()).decimals());
    }

    /**
     * @dev lay eggs
     */
    function layEgg(uint256 fatherID, uint256 motherID)
        public
        payable
        virtual
        returns (uint256)
    {
        layCan(fatherID, motherID);
        uint256 price = layCoin(fatherID, motherID);
        if (
            ICoin(reg.umyAddr()).transferFrom(msg.sender, reg.financer(), price)
        ) {
            _pets[fatherID].breed++;
            _pets[motherID].breed++;
            return IEgg(reg.eggAddr()).newEgg(msg.sender, fatherID, motherID);
        }
        revert("error");
    }

    /**
     * @dev get pet number of evolution
     */
    function evolveNum(uint256 id) public view virtual returns (uint256) {
        return _evolveNums[id];
    }

    /**
     * @dev determine whether pets can evolve
     */
    function evolveCan(uint256 petID) public view virtual returns (bool) {
        Pet memory pet = _pets[petID];

        // must onwer
        require(
            pet.htime > 0 && INFT(reg.nftAddr()).ownerOf(petID) == msg.sender
        );
        // evolve times
        uint256 num = pet.notum.grade +
            pet.horn.grade +
            pet.mouth.grade +
            pet.tail.grade -
            3;
        require(num <= pet.elimit);

        return true;
    }

    /**
     * @dev calculate the gold needed for evolution
     */
    function evolveCoin(uint256 petID) public view virtual returns (uint256) {
        Pet memory pet = _pets[petID];
        uint256 num = pet.notum.grade +
            pet.horn.grade +
            pet.mouth.grade +
            pet.tail.grade -
            3;
        return num * 5 * reg.umyPrice() * (10 ** ICoin(reg.umyAddr()).decimals());
    }
    

    function _evolveGene(uint256 petID, uint256[] memory ids, address account) private view returns(GeneRate memory, uint8) {
        // body rate
        Pet memory pet = _pets[petID];
        GeneRate[4] memory genes = [
            GeneRate(PetBody.Notum, 25, pet.notum.deity),  // order 1
            GeneRate(PetBody.Horn, 25, pet.horn.deity), // order 2
            GeneRate(PetBody.Mouth, 25, pet.mouth.deity), // order 3
            GeneRate(PetBody.Tail, 25, pet.tail.deity) // order last
        ];
        // eat other pet
        INFT nft = INFT(reg.nftAddr());
        bool deityCan = pet.elimit > 20;
        uint8 elimit = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            Pet memory pet1 = _pets[ids[i]];
            require(
                pet1.htime > 0 && (nft.ownerOf(ids[i]) == account) && ids[i] != petID && (nft.isLocked(ids[i]) == false)
            ); // must owner
            _evolveRate(genes[0], pet.notum, pet1.notum, deityCan);
            _evolveRate(genes[1], pet.horn, pet1.horn, deityCan);
            _evolveRate(genes[2], pet.mouth, pet1.mouth, deityCan);
            _evolveRate(genes[3], pet.tail, pet1.tail, deityCan);
            if (pet1.elimit > elimit) {
                elimit = pet1.elimit;
            }
        }
        // calc body, order: same ID > lowest grade > notum horn mouth tail
        uint256 rate = 0;
        for (uint256 i = 0; i < genes.length - 1; i++) {
            rate = rand(99, rate) + 1;
            if (rate <= genes[i].rate) {
                return (genes[i], elimit);
            }
        }
        return (genes[genes.length - 1], elimit);
    }

    /**
     * @dev pet evolution
     * can eat other, will improve the deity
     */
    function evolve(uint256 petID, uint256[] memory ids)
        public
        payable
        virtual
    {
        evolveCan(petID);
        // after 10 must eat other pets
        if (_evolveNums[petID] > 10) {
            require(ids.length > 0);
        }
        uint256 price = evolveCoin(petID);
        if (
            ICoin(reg.umyAddr()).transferFrom(msg.sender, reg.financer(), price)
        ) {
            (GeneRate memory gene, uint8 elimit) = _evolveGene(petID, ids, msg.sender);
            // the body rate
            Pet storage pet = _pets[petID];
            _evolveGrade(pet, gene);
            // elimit low 3 to 1 normal
            if (ids.length >= 3 && pet.elimit <= 20 && elimit <=20) {
                pet.elimit = 50;
            } else if (pet.elimit <= 80 && pet.elimit > 20 && elimit > 20) {
                // grade mutation
                uint256 rate = rand(999, elimit) + 1;
                if (rate <=5 ) {
                    if (pet.elimit >= 80 && elimit >= 80) {
                        pet.elimit = 120;
                    } else {
                        pet.elimit = 80;
                    }
                }
            }
            if (elimit > pet.elimit) {
                pet.elimit = elimit;
            }
            // brun pet
            INFT nft = INFT(reg.nftAddr());
            for (uint256 i = 0; i < ids.length; i++) {
                nft.burnFor(ids[i]);
            }
            _evolveNums[petID] += 1;
            emit Evolve(petID, pet);
            return;
        }
        revert("transfer error");
    }


    function _evolveMax(
        GeneRate[] memory genes,
        uint256 start,
        uint256 len
    ) internal pure virtual {
        for (uint256 i = start + 1; i < len; i++) {
            if (genes[i].rate > genes[start].rate) {
                GeneRate memory x = genes[start];
                genes[start] = genes[i];
                genes[i] = x;
            }
        }
    }

 
    function _evolveGrade(Pet storage pet, GeneRate memory gene)
        internal
        virtual
    {
        if (gene.body == PetBody.Notum) {
            pet.notum.grade += 1;
            pet.notum.deity = gene.deity;
        } else if (gene.body == PetBody.Horn) {
            pet.horn.grade += 1;
            pet.horn.deity = gene.deity;
        } else if (gene.body == PetBody.Mouth) {
            pet.mouth.grade += 1;
            pet.mouth.deity = gene.deity;
        } else if (gene.body == PetBody.Tail) {
            pet.tail.grade += 1;
            pet.tail.deity = gene.deity;
        }
    }


    function _evolveRate(
        GeneRate memory gene,
        PetGene memory pet,
        PetGene memory pet1,
        bool deityCan
    ) internal view virtual {
        if (pet.appea == pet1.appea) {
            gene.rate += 15;
        }
        if (pet.hidden == pet1.hidden) {
            gene.rate += 10;
        }

        // deity must < 100
        if (deityCan && (gene.deity < 100)) {
            // get the max deity
            if (pet1.deity > gene.deity) {
                (gene.deity, pet1.deity) = (pet1.deity, gene.deity);
            }
            if (gene.deity > 0) {
                gene.deity += uint8(uint256(pet1.deity) * (pet1.deity < 6 ? pet1.deity : 6) / gene.deity);
            }
            if (gene.deity > 100) {
                gene.deity = 100;
            }
        }
    }

    /**
     * @dev random the gene
     */
    function _randGene(
        PetBody body,
        uint256 deity,
        uint256 id
    ) internal view virtual returns (PetGene memory) {
        uint256 bodyint = uint256(body);
        // start 1
        uint256 count = reg.geneNum(bodyint) - 1;

        uint256 gen1 = rand(count, id + bodyint + 1);
        uint256 gen2 = rand(count, id + bodyint + gen1);
        return
            PetGene(
                uint8(gen1) + 1,
                uint8(gen2) + 1,
                uint8(deity), // deity
                1
            );
    }

    /**
     * acquire a genetic gene
     */
    function _newGene(
        PetBody body,
        PetGene memory father,
        PetGene memory mother
    ) internal view virtual returns (PetGene memory) {
        uint256 bodyint = uint256(body);

        // deity parent/4
        uint8 deity = (father.deity + mother.deity) / 4;

        // appea 40%，hidden10%
        uint8[4] memory genes = [
            father.appea,
            mother.appea,
            father.hidden,
            mother.hidden
        ];
        uint256 index = rand(1, bodyint + deity);
        uint8 appea = rand(99, bodyint + index) < 80
            ? genes[index]
            : genes[index + 2];

        // hidden, without appea
        index = 0;
        uint8[] memory genes1 = new uint8[](3);
        for (uint256 i = 0; i < genes.length; i++) {
            if (genes[i] != appea) {
                genes1[index] = genes[i];
                index++;
            }
        }
        uint8 hidden = genes1[rand(index - 1, appea + deity)];

        return PetGene(appea, hidden, deity, 1);
    }

    /**
     * @dev random a integer 0 - max
     * must different seed in a call 
     */
    function rand(uint256 max, uint256 seed)
        private
        view
        returns (uint256)
    {
        if (max == 0) {
            return 0;
        }
        uint256 _rand = uint256(
            keccak256(
                abi.encodePacked(
                    seed,
                    INFT(reg.nftAddr()).amount(),
                    ICoin(reg.umyAddr()).balanceOf(reg.financer()),
                    block.number,
                    block.difficulty
                )
            )
        );
        return _rand % (max + 1);
    }
}
