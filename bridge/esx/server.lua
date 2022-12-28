if GetResourceState('es_extended') ~= 'started' then return end

ESX = exports.es_extended:getSharedObject()

function RegisterCallback(name, cb)
    ESX.RegisterServerCallback(name, cb)
end

function ShowNotification(target, text)
	TriggerClientEvent(GetCurrentResourceName()..":showNotification", target, text)
end

function Search(source, name)
    local xPlayer = ESX.GetPlayerFromId(source)
    if (name == "money") then
        return xPlayer.getMoney()
    elseif (name == "bank") then
        return xPlayer.getAccount('bank').money
    else
        local item = xPlayer.getInventoryItem(name)
        if item ~= nil then 
            return item.count
        else
            return 0
        end
    end
end

function AddItem(source, name, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if (name == "money") then
        return xPlayer.addMoney(amount)
    elseif (name == "bank") then
        return xPlayer.addAccountMoney('bank', amount)
    else
        return xPlayer.addInventoryItem(name, amount)
    end
end

function RemoveItem(source, name, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if (name == "money") then
        return xPlayer.removeMoney(amount)
    elseif (name == "bank") then
        return xPlayer.removeAccountMoney('bank', amount)
    else
        return xPlayer.removeInventoryItem(name, amount)
    end
end

function CanAccessGroup(source, data)
    if not data then return true end
    local pdata = ESX.GetPlayerFromId(source)
    for k,v in pairs(data) do 
        if (pdata.job.name == k and pdata.job.grade >= v) then return true end
    end
    return false
end 

function GetIdentifier(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer.identifier
end

function AttemptTransaction(paymentCFG, data)
    local targetMoney = Search(data.target, "money")
    local targetBank = Search(data.target, "bank")
    local paymentMethod = "money"
    local bill = data.bill
    if targetMoney - bill.price < 0 then 
        if targetBank - bill.price >= 0 then 
            paymentMethod = "bank"
        else
            return false, _L("cant_afford_target", data.cashier), _L("cant_afford_source", data.target)
        end
    end
    if (paymentCFG.Type == "society") then 
        if paymentMethod == "money" then 
            RemoveItem(data.target, "money", bill.price)
            TriggerEvent('esx_addonaccount:getSharedAccount', paymentCFG.Society, function(account)
                account.addMoney(bill.price)
            end)
        elseif paymentMethod == "bank" then 
            RemoveItem(data.target, "bank", bill.price)
            TriggerEvent('esx_addonaccount:getSharedAccount', paymentCFG.Society, function(account)
                account.addMoney(bill.price)
            end)
        end
        return true, _L("success_target", bill.price, _L("payment_method_".. paymentMethod), data.cashier), _L("success_source", bill.price, _L("payment_method_".. paymentMethod), data.target)
    elseif (paymentCFG.Type == "player") then
        if paymentMethod == "money" then 
            RemoveItem(data.target, "money", bill.price)
            AddItem(data.cashier, "money", bill.price)
        elseif paymentMethod == "bank" then 
            RemoveItem(data.target, "bank", bill.price)
            AddItem(data.cashier, "bank", bill.price)
        end
        return true, _L("success_target", bill.price, _L("payment_method_".. paymentMethod), data.cashier), _L("success_source", bill.price, _L("payment_method_".. paymentMethod), data.target)
    end
end