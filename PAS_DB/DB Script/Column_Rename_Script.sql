--Need to Execute each SP_Rename Query seperately
sp_RENAME 'PAS_DEV.dbo.ItemMaster.DER', 'IsDER' , 'COLUMN';
sp_RENAME 'PAS_DEV.dbo.ItemMaster.isPma', 'IsPma' , 'COLUMN';
sp_RENAME 'PAS_DEV.dbo.ItemMaster.oemPNId', 'IsOemPNId' , 'COLUMN';
sp_RENAME 'PAS_DEV.dbo.ItemMaster.AssetAcquistionTypeId', 'ItemMasterAssetTypeId' , 'COLUMN';