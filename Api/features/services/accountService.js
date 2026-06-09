const {AccountModel} = require('../models/account/account');

class AccountService {
    constructor() {}

    async NewAccount(_id, name, email, phone, password) {
        try {
            if(_id != null) {
                return await AccountModel.findByIdAndUpdate(_id, {name, email, phone, password}).exec();
            }
            const acocunt = new AccountModel({
                name, email, password, phone
            });
            await acocunt.save();
            return true;
        }
        catch(e) {
            return e;
        }
        return false;
    }

    async Login(email, password, res) {
    try {

        const user = await AccountModel.findOne({
            email: email
        }).exec();

        console.log("USER LOGIN:", user);
        console.log("INPUT PASSWORD:", password);
        console.log("DB PASSWORD:", user.password);


        if (!user) {
            return null;
        }


        if (user.password !== password) {
            console.log("PASSWORD NOT MATCH");
            return null;
        }


        console.log("LOGIN SUCCESS");

        return user;

    } catch(e) {
        return res.status(500).send(e);
    }
}

    async GetList(res) {
        try {
            return await AccountModel.find().exec();
        }
        catch(e) {
            return res.status(500).send(e);
        }
    }

    async GetById(_id, res) {
        try {
            return await AccountModel.findById(_id).exec();
        }
        catch(e) {
            return res.status(500).send(e);
        }
    }
    async delete(_id, res) {
        try {
            return await AccountModel.findByIdAndDelete(_id).exec();
        }
        catch(e) {
            return res.status(500).send(e);
        }
    }
    async GetByEmail(email, res) {
        try {
            return await AccountModel.findOne({email: email}).exec();
        }
        catch(e) {
            return res.status(500).send(e);
        }
    }
    async SignupUpdate(data, res) {
    try {

        const {
            name,
            email,
            phone,
            password
        } = data;

        console.log("REGISTER:", {
            name,
            email,
            phone,
            password
        });


        let account = await AccountModel.findOne({
            email: email
        });


        if (account) {
            account.name = name;
            account.phone = phone;
            account.password = password;

            await account.save();

            return true;
        }


        account = new AccountModel({
            name,
            email,
            phone,
            password
        });


        await account.save();

        return true;


    } catch(e) {
        console.log(e);
        return res.status(500).send(e);
    }
}
}
module.exports = AccountService;