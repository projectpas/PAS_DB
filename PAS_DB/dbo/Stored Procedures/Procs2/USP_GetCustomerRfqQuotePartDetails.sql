/*************************************************************           
 ** File:   [USP_GetCustomerRfqQuotePartDetails]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used USP_GetCustomerRfqQuotePartDetails
 ** Purpose:         
 ** Date:   20/02/2023      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    20/02/2023  Amit Ghediya    Created
     
-- EXEC USP_GetCustomerRfqQuotePartDetails '1211318-006',1,1,'ARKWIN'
************************************************************************/
CREATE        PROCEDURE [dbo].[USP_GetCustomerRfqQuotePartDetails] 
@PartNumber VARCHAR(50),
@LegalEntityId BIGINT,
@MasterCompanyId INT,
@ManufacturerName VARCHAR(50) NULL
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
  BEGIN TRY  
    BEGIN TRANSACTION  
  
		  DECLARE @ManufactureId BIGINT, @OverHaulCondId BIGINT, @RepairCondId BIGINT, @BenchCheckCondId BIGINT, 
				  @OverHaulSalePrice DECIMAL(10,2),@OverHaulMaxSalePrice DECIMAL(10,2),@OverHaulMinSalePrice DECIMAL(10,2),@OverHaulAvgSalePrice DECIMAL(10,2),@OverHaulAvgTat INT, @OverHaulTotalDays INT,  @OverHaulCount INT,
				  @RepairSalePrice DECIMAL(10,2), @RepairMaxSalePrice DECIMAL(10,2), @RepairMinSalePrice DECIMAL(10,2), @RepairAvgSalePrice DECIMAL(10,2),@RepairAvgTat INT, @RepairTotalDays INT,  @RepairCount INT,
				  @BenchSalePrice DECIMAL(10,2),@BenchMaxSalePrice DECIMAL(10,2),@BenchMinSalePrice DECIMAL(10,2),@BenchAvgSalePrice DECIMAL(10,2),@BenchAvgTat INT, @BenchTotalDays INT,  @BenchCount INT;

		  SELECT @ManufactureId = ManufacturerId FROM Manufacturer WHERE Name = @ManufacturerName;

		  SELECT @OverHaulCondId = ConditionId FROM Condition where Code='OVERHAUL' AND MasterCompanyId = @MasterCompanyId;
		  SELECT @RepairCondId = ConditionId FROM Condition where Code='REPAIR' AND MasterCompanyId = @MasterCompanyId;
          SELECT @BenchCheckCondId = ConditionId FROM Condition where Code='BENCH CHECK' AND MasterCompanyId = @MasterCompanyId;

		  ---- Get Data ------
		  SELECT IsNull(iM.TurnTimeOverhaulHours,0) AS TurnTimeOverhaulHours,
				 IsNull(iM.TurnTimeRepairHours,0) AS TurnTimeRepairHours,
				 IsNull(iM.turnTimeBenchTest,0) AS turnTimeBenchTest,
				 IsNull(iM.turnTimeMfg,0) AS turnTimeMfg
		 FROM ItemMaster iM WITH (NOLOCK)
		 WHERE iM.partnumber= @PartNumber AND iM.ManufacturerId = @ManufactureId; --'A3125442000';
		 
		 ---------------Get Max/Min/AVG Value for OverHaul form Stockline table ----
		 SELECT @OverHaulMaxSalePrice = MAX(UnitCost),
				@OverHaulMinSalePrice = MIN(UnitCost),
				@OverHaulAvgSalePrice = AVG(UnitCost)
		 FROM Stockline WITH (NOLOCK)
		 WHERE IsCustomerStock=0 AND IsParent=1 AND PartNumber = @PartNumber AND ConditionId=@OverHaulCondId;
		 
		 ---------------------GET OverHaulTAT --------------------------------
		 SELECT @OverHaulCount = Count(*)
			FROM WorkOrderPartNumber wopn
		 INNER JOIN Condition con ON wopn.ConditionId = con.ConditionId AND con.ConditionId = @OverHaulCondId
		 INNER JOIN ItemMaster im ON wopn.ItemMasterId = im.ItemMasterId
		 LEFT JOIN WorkOrderTurnArroundTime wotat ON wopn.ID = wotat.WorkOrderPartNoId
		 LEFT JOIN WorkOrderStage wos ON wotat.CurrentStageId = wos.WorkOrderStageId AND wos.IncludeInStageReport = 1
		 WHERE im.partnumber = @PartNumber AND wopn.IsClosed = 1 AND wopn.MasterCompanyId=1;		 

		 SELECT @OverHaulTotalDays = SUM(wotat.Days)--,@OverHaulCount = Count(*)
			FROM WorkOrderPartNumber wopn
		 INNER JOIN Condition con ON wopn.ConditionId = con.ConditionId AND con.ConditionId = @OverHaulCondId
		 INNER JOIN ItemMaster im ON wopn.ItemMasterId = im.ItemMasterId
		 LEFT JOIN WorkOrderTurnArroundTime wotat ON wopn.ID = wotat.WorkOrderPartNoId
		 LEFT JOIN WorkOrderStage wos ON wotat.CurrentStageId = wos.WorkOrderStageId AND wos.IncludeInStageReport = 1
		 WHERE im.partnumber = @PartNumber AND wopn.IsClosed = 1 AND wopn.MasterCompanyId = @MasterCompanyId
		 group by wotat.WorkOrderPartNoId;
		 IF(@OverHaulTotalDays > @OverHaulCount)
		 BEGIN
			SET @OverHaulAvgTat = @OverHaulTotalDays / @OverHaulCount;
		 END
		 ELSE
		 BEGIN
				SET @OverHaulAvgTat = @OverHaulTotalDays;
		 END
		 --SET @OverHaulAvgTat = @OverHaulTotalDays;
		 

		 --- Get OverHaul Data ------
		 SET @OverHaulSalePrice = ( SELECT 
				IsNull(iMS.SP_CalSPByPP_UnitSalePrice, 0.00)
		 FROM ItemMaster iM WITH (NOLOCK)
		 LEFT JOIN ItemMasterPurchaseSale iMS WITH (NOLOCK) ON im.ItemMasterId = iMS.ItemMasterId AND iMS.ConditionId = @OverHaulCondId
		 WHERE iM.partnumber= @PartNumber AND iM.ManufacturerId = @ManufactureId);

		 ---------------Get Max/Min/AVG Value for Repair form Stockline table ----
		 SELECT @RepairMaxSalePrice = MAX(UnitCost),
				@RepairMinSalePrice = MIN(UnitCost),
				@RepairAvgSalePrice = AVG(UnitCost)
		 FROM Stockline WITH (NOLOCK)
		 WHERE IsCustomerStock=0 AND IsParent=1 AND PartNumber = @PartNumber AND ConditionId=@RepairCondId;

		 ---------------------GET RepairTAT --------------------------------

		 SELECT @RepairCount = Count(*)
			FROM WorkOrderPartNumber wopn
		 INNER JOIN Condition con ON wopn.ConditionId = con.ConditionId AND con.ConditionId = @RepairCondId
		 INNER JOIN ItemMaster im ON wopn.ItemMasterId = im.ItemMasterId
		 LEFT JOIN WorkOrderTurnArroundTime wotat ON wopn.ID = wotat.WorkOrderPartNoId
		 LEFT JOIN WorkOrderStage wos ON wotat.CurrentStageId = wos.WorkOrderStageId AND wos.IncludeInStageReport = 1
		 WHERE im.partnumber = @PartNumber AND wopn.IsClosed = 1 AND wopn.MasterCompanyId=1
		 group by wotat.WorkOrderPartNoId;

		 SELECT @RepairTotalDays = SUM(wotat.Days)--,@RepairCount = Count(*)
			FROM WorkOrderPartNumber wopn
		 INNER JOIN Condition con ON wopn.ConditionId = con.ConditionId AND con.ConditionId = @RepairCondId
		 INNER JOIN ItemMaster im ON wopn.ItemMasterId = im.ItemMasterId
		 LEFT JOIN WorkOrderTurnArroundTime wotat ON wopn.ID = wotat.WorkOrderPartNoId
		 LEFT JOIN WorkOrderStage wos ON wotat.CurrentStageId = wos.WorkOrderStageId AND wos.IncludeInStageReport = 1
		 WHERE im.partnumber = @PartNumber AND wopn.IsClosed = 1 AND wopn.MasterCompanyId = @MasterCompanyId;
		 
		 IF(@RepairTotalDays > @RepairCount)
		 BEGIN
				SET @RepairAvgTat = @RepairTotalDays / @RepairCount;
		 END
		 ELSE
		 BEGIN
			SET @RepairAvgTat = @RepairTotalDays;
		 END
		 --SET @RepairAvgTat = @RepairTotalDays;
		 

		  ---- Get Repair Data ------
		 SET @RepairSalePrice = (SELECT 
				IsNull(iMS.SP_CalSPByPP_UnitSalePrice, 0.00)
		 FROM ItemMaster iM WITH (NOLOCK)
		 LEFT JOIN ItemMasterPurchaseSale iMS WITH (NOLOCK) ON im.ItemMasterId = iMS.ItemMasterId AND iMS.ConditionId = @RepairCondId
		 WHERE iM.partnumber= @PartNumber AND iM.ManufacturerId = @ManufactureId);

		  ---------------Get Max/Min/AVG Value for BenchCheck form Stockline table ----
		 SELECT @BenchMaxSalePrice = MAX(UnitCost),
				@BenchMinSalePrice = MIN(UnitCost),
				@BenchAvgSalePrice = AVG(UnitCost)
		 FROM Stockline WITH (NOLOCK)
		 where IsCustomerStock=0 AND IsParent=1 AND PartNumber = @PartNumber AND ConditionId=@BenchCheckCondId;

		 ---------------------GET BenchtTAT --------------------------------
		 SELECT @BenchCount = Count(*)
			FROM WorkOrderPartNumber wopn
		 INNER JOIN Condition con ON wopn.ConditionId = con.ConditionId AND con.ConditionId = @BenchCheckCondId
		 INNER JOIN ItemMaster im ON wopn.ItemMasterId = im.ItemMasterId
		 LEFT JOIN WorkOrderTurnArroundTime wotat ON wopn.ID = wotat.WorkOrderPartNoId
		 LEFT JOIN WorkOrderStage wos ON wotat.CurrentStageId = wos.WorkOrderStageId AND wos.IncludeInStageReport = 1
		 WHERE im.partnumber = @PartNumber AND wopn.IsClosed = 1 AND wopn.MasterCompanyId=1
		 group by wotat.WorkOrderPartNoId;

		 SELECT @BenchTotalDays = SUM(wotat.Days)--,@BenchCount = Count(*)
			FROM WorkOrderPartNumber wopn
		 INNER JOIN Condition con ON wopn.ConditionId = con.ConditionId AND con.ConditionId = @BenchCheckCondId
		 INNER JOIN ItemMaster im ON wopn.ItemMasterId = im.ItemMasterId
		 LEFT JOIN WorkOrderTurnArroundTime wotat ON wopn.ID = wotat.WorkOrderPartNoId
		 LEFT JOIN WorkOrderStage wos ON wotat.CurrentStageId = wos.WorkOrderStageId AND wos.IncludeInStageReport = 1
		 WHERE im.partnumber = @PartNumber AND wopn.IsClosed = 1 AND wopn.MasterCompanyId = @MasterCompanyId;
		
		 IF(@BenchTotalDays > @BenchCount)
		 BEGIN
				 SET @BenchAvgTat = @BenchTotalDays / @BenchCount;
		 END
		 ELSE
		 BEGIN
				 SET @BenchAvgTat = @BenchTotalDays ;
		 END
		 --SET @BenchAvgTat = @BenchTotalDays / @BenchCount;
		

		 ---- Get Bench Check Data ------
		 SET @BenchSalePrice = (SELECT 
				IsNull(iMS.SP_CalSPByPP_UnitSalePrice, 0.00)
		 FROM ItemMaster iM WITH (NOLOCK)
		 LEFT JOIN ItemMasterPurchaseSale iMS WITH (NOLOCK) ON im.ItemMasterId = iMS.ItemMasterId AND iMS.ConditionId = @BenchCheckCondId
		 WHERE iM.partnumber= @PartNumber AND iM.ManufacturerId = @ManufactureId);

		 SELECT IsNull(@OverHaulSalePrice, 0.00) AS OverHaulSalePrice, IsNull(@OverHaulMaxSalePrice,0.00) AS OverHaulMaxSalePrice, IsNull(@OverHaulMinSalePrice,0.00) AS OverHaulMinSalePrice,IsNull(@OverHaulAvgSalePrice,0.00) AS  OverHaulAvgSalePrice,
		 IsNull(@RepairSalePrice,0.00) AS RepairSalePrice, IsNull(@RepairMaxSalePrice,0.00) AS RepairMaxSalePrice, IsNull(@RepairMinSalePrice,0.00) AS RepairMinSalePrice, IsNull(@RepairAvgSalePrice,0.00) AS RepairAvgSalePrice,
		 IsNull(@BenchSalePrice,0.00) AS BenchSalePrice, IsNull(@BenchMaxSalePrice,0.00) AS BenchMaxSalePrice, IsNull(@BenchMinSalePrice,0.00) AS BenchMinSalePrice, IsNull(@BenchAvgSalePrice,0.00) AS BenchAvgSalePrice,
		 IsNull(@OverHaulAvgTat,0) AS OverHaulAvgTat, IsNull(@RepairAvgTat,0) AS RepairAvgTat, IsNull(@BenchAvgTat,0) AS BenchAvgTat;

		 SELECT LE.Name,
				(ISNULL(Ad.Line1,'')+' '+ISNULL(Ad.Line2,'') +' '+ISNULL(Ad.Line3,'')) As RAddress,
				Ad.City,
				Co.countries_name,
				LE.PhoneNumber, LE.FaxNumber
		 FROM LegalEntity LE WITH (NOLOCK)
		 LEFT JOIN Address Ad WITH (NOLOCK) ON LE.AddressId = Ad.AddressId
		 LEFT JOIN Countries Co WITH (NOLOCK) ON Ad.CountryId = Co.countries_id
		 WHERE LE.LegalEntityId = @LegalEntityId;

    COMMIT TRANSACTION  
  END TRY  
  
  BEGIN CATCH  
    ROLLBACK TRANSACTION   
   
  
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,  
            @AdhocComments varchar(150) = '[USP_GetCustomerRfqQuotePartDetails]',  
            @ProcedureParameters varchar(3000) = '@PartNumber = ''' + CAST(ISNULL(@PartNumber, '') AS varchar(100)) ,  
            @ApplicationName varchar(100) = 'PAS'  
  
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH  
  
END