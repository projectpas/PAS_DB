CREATE PROCEDURE [dbo].[USP_UPSRTCALIBRATION]  
@AssetInventoryId bigint,  
@Status BIT,  
@MasterCompanyID int,  
@CreatedBy varchar(50),  
@VendorId bigint  
AS  
BEGIN  
  if @Status=0  
  BEGIN  
  IF EXISTS (SELECT top 1 *  FROM AssetInventory WITH (NOLOCK) WHERE AssetInventoryId=@AssetInventoryId  and CalibrationRequired=1)  
  BEGIN  
  IF EXISTS (select top 1 * from CalibrationManagment WITH (NOLOCK) where AssetInventoryId=@AssetInventoryId and CertifyType='Calibration' and IsActive=1)  
  BEGIN  
  DELETE FROM CalibrationManagment  where AssetInventoryId=@AssetInventoryId and CertifyType='Calibration' and IsActive=1  
  END  
  INSERT INTO [dbo].[CalibrationManagment]  
           ([AssetRecordId] ,[LastCalibrationDate],[NextCalibrationDate],[LastCalibrationBy]  
           ,[VendorId],[CalibrationDate],[CurrencyId],[UnitCost], [CertifyType],[MasterCompanyId],  
     [IsDeleted],[IsActive] ,[CreatedBy],[UpdatedBy],  
     [CreatedDate],[UpdatedDate],[IsVendororEmployee],[AssetInventoryId],[CalibrationTypeId])  
       
    SELECT AsI.AssetRecordId,GETDATE(),  
    DATEADD(DAY, ISNULL(Assc.CalibrationFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.CalibrationFrequencyMonths,0),getdate())),  
    @CreatedBy,@VendorId,GETDATE(),AsI.CurrencyId,AsI.UnitCost,'Calibration',@MasterCompanyID,  
    0,0,@CreatedBy,@CreatedBy,GETDATE(),GETDATE(),'vendor',AsI.AssetInventoryId,1  
  
    FROM   
    AssetInventory As AsI WITH(NOLOCK)  
    LEFT JOIN dbo.AssetCalibration  AS Assc WITH(NOLOCK) ON Assc.AssetRecordId=AsI.AssetRecordId  
    where AsI.AssetInventoryId=@AssetInventoryId  
  END  
  END  
  ELSE IF @Status=1  
  BEGIN  
  IF EXISTS (SELECT top 1 * FROM CalibrationManagment WITH (NOLOCK) where AssetInventoryId=@AssetInventoryId and CertifyType='Calibration')  
   BEGIN  
   DELETE FROM CalibrationManagment  where AssetInventoryId=@AssetInventoryId and CertifyType='Calibration'  
  END  
  END  
  
END