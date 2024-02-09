/*************************************************************           
 ** File:   [USP_GetAllIntegrationPartOffline]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used to add update integration part like ILS,145 etc...
 ** Purpose:         
 ** Date:   23/01/2024      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   ----------  -----------	--------------------------------          
    1    23/01/2024  Rajesh Gami	Created
     
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetAllIntegrationPartOffline]
	@PartNumber varchar(200),
	@IntegrationPortalId int = NULL,	
	@ConditionIds varchar(max) = NULL,
	@MasterCompanyId int,
	@IsAll bit = 0
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN		
			DECLARE @ILSName varchar(20) = 'ILS', @145Name varchar(20) ='145.COM',@AEXName varchar(20) ='AEX';
			DECLARE @PortalType varchar(20) = (SELECT TOP 1 Description FROM DBO.IntegrationPortal WITH(NOLOCK) WHERE IntegrationPortalId = @IntegrationPortalId);
			DECLARE @LatestId BIGINT = 0;
			DECLARE @IlsIntegrationPortalId INT = 0, @OneFourtyIntegrationPortalId INT = 0;
			IF OBJECT_ID(N'tempdb..#tempTableIntegration') IS NOT NULL
			BEGIN
				DROP TABLE #tempTableIntegration
			END
			CREATE TABLE #tempTableIntegration(
			   [ID] [bigint] NULL
			)
			SET @ConditionIds = (CASE WHEN @ConditionIds = '' THEN NULL ELSE @ConditionIds END)
			SET @PartNumber = (CASE WHEN @PartNumber = '' THEN NULL ELSE @PartNumber END)
			IF(@IsAll = 0) /***** Start: @IsAll = 0 ******/
			BEGIN
					IF(UPPER(@PortalType) = UPPER(@145Name))  /**** Start:  145 Integration ******/
					BEGIN
					
						   SELECT im.IntegrationMasterId,
							im.PartNumber,
							im.PartDescription,
							im.RepairStation,
							im.IsRepair,
							im.PhoneNumber,
							im.IntegrationPortalId,
							im.IntegrationPortal,
							ofc.OneFourtyFiveChildPartId,
							ofc.RepairCertiNo,
							ofc.LastUpdate,
							ofc.QuoteDate,
							ofc.OHPrice,
							ofc.OHTAT,
							ofc.RepairPrice,
							ofc.RepairTAT,
							ofc.TestPrice,
							ofc.TestTAT,
							ofc.WebLink,
							ofc.[Location] AS Location,
							im.MasterCompanyId,
							im.UpdatedBy,
							im.UpdatedDate
						FROM DBO.IntegrationMaster IM WITH (NOLOCK) 
						INNER JOIN [dbo].[OneFourtyFiveChildPartDetail] OFC WITH (NOLOCK) ON IM.IntegrationMasterId = OFC.IntegrationMasterId
						WHERE (@PartNumber IS NULL OR IM.PartNumber = @PartNumber) AND IM.IntegrationPortalId = @IntegrationPortalId AND Im.MasterCompanyId = @MasterCompanyId

				END   /**** End:  145 Integration ******/
				ELSE IF(UPPER(@PortalType) = UPPER(@ILSName)) /**** Start:  ILS Integration ******/
				BEGIN
					 SELECT im.IntegrationMasterId,
							im.PartNumber,
							im.PartDescription,
							im.RepairStation,
							im.IsRepair,
							im.PhoneNumber,
							im.IntegrationPortalId,
							im.IntegrationPortal,
							ils.ILSChildPartId,
							ils.AltPartNumber,
							ils.Qty,
							ils.Cage,
							ils.Condition,
							ils.Distance,
							ils.ExchangeOption,
							im.MasterCompanyId,
							im.UpdatedBy,
							im.UpdatedDate
						FROM DBO.IntegrationMaster IM WITH (NOLOCK) 
						INNER JOIN [dbo].[ILSChildPartDetail] ILS WITH (NOLOCK) ON IM.IntegrationMasterId = ILS.IntegrationMasterId
						WHERE (@PartNumber IS NULL OR IM.PartNumber = @PartNumber) AND IM.IntegrationPortalId = @IntegrationPortalId AND Im.MasterCompanyId = @MasterCompanyId AND (@ConditionIds IS NULL OR ILS.Condition IN(SELECT * FROM STRING_SPLIT(@ConditionIds , ',')))
				END  /**** END:  ILS Integration ******/
			END /***** End: @IsAll = 0 ******/
			ELSE
			BEGIN /***** ALL Record *******/
					SET @IlsIntegrationPortalId = (SELECT TOP 1 IntegrationPortalId FROM DBO.IntegrationPortal WITH(NOLOCK) WHERE UPPER(Description) =  UPPER(@ILSName) AND MasterCompanyId = @MasterCompanyId)
					SET @OneFourtyIntegrationPortalId = (SELECT TOP 1 IntegrationPortalId FROM DBO.IntegrationPortal WITH(NOLOCK) WHERE UPPER(Description) =  UPPER(@145Name) AND MasterCompanyId = @MasterCompanyId)
					PRINT @IlsIntegrationPortalId
					PRINT @OneFourtyIntegrationPortalId
					SELECT im.IntegrationMasterId,
							im.PartNumber,
							im.PartDescription,
							im.RepairStation,
							im.IsRepair,
							im.PhoneNumber,
							im.IntegrationPortalId,
							im.IntegrationPortal,
							ofc.OneFourtyFiveChildPartId,
							ofc.RepairCertiNo,
							ofc.LastUpdate,
							ofc.QuoteDate,
							ofc.OHPrice,
							ofc.OHTAT,
							ofc.RepairPrice,
							ofc.RepairTAT,
							ofc.TestPrice,
							ofc.TestTAT,
							ofc.WebLink,
							ofc.[Location] AS Location,

							0 ILSChildPartId,
						    '' AltPartNumber,
							0 Qty,
							'' Cage,
							'' Condition,
							'' Distance,
							'' ExchangeOption,

							im.MasterCompanyId,
							im.UpdatedBy,
							im.UpdatedDate
						FROM DBO.IntegrationMaster IM WITH (NOLOCK) 
						INNER JOIN [dbo].[OneFourtyFiveChildPartDetail] OFC WITH (NOLOCK) ON IM.IntegrationMasterId = OFC.IntegrationMasterId
						WHERE (@PartNumber IS NULL OR IM.PartNumber = @PartNumber) AND IM.IntegrationPortalId = @OneFourtyIntegrationPortalId AND Im.MasterCompanyId = @MasterCompanyId
					
					UNION ALL

					 SELECT im.IntegrationMasterId,
							im.PartNumber,
							im.PartDescription,
							im.RepairStation,
							im.IsRepair,
							im.PhoneNumber,
							im.IntegrationPortalId,
							im.IntegrationPortal,
							0 OneFourtyFiveChildPartId,
							'' RepairCertiNo,
							'' LastUpdate,
							NULL QuoteDate,
							0 OHPrice,
							'' OHTAT,
							0 RepairPrice,
							'' RepairTAT,
							0 TestPrice,
							'' TestTAT,
							'' WebLink,
							''AS Location,

							ils.ILSChildPartId,
							ils.AltPartNumber,
							ils.Qty,
							ils.Cage,
							ils.Condition,
							ils.Distance,
							ils.ExchangeOption,
							im.MasterCompanyId,
							im.UpdatedBy,
							im.UpdatedDate
						FROM DBO.IntegrationMaster IM WITH (NOLOCK) 
						INNER JOIN [dbo].[ILSChildPartDetail] ILS WITH (NOLOCK) ON IM.IntegrationMasterId = ILS.IntegrationMasterId
						WHERE (@PartNumber IS NULL OR IM.PartNumber = @PartNumber) AND IM.IntegrationPortalId = @IlsIntegrationPortalId AND Im.MasterCompanyId = @MasterCompanyId AND (@ConditionIds IS NULL OR ILS.Condition IN(SELECT * FROM STRING_SPLIT(@ConditionIds , ',')))
			END		
		END
	COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
		    SELECT  
			 ERROR_NUMBER() AS ErrorNumber  
            ,ERROR_SEVERITY() AS ErrorSeverity  
            ,ERROR_STATE() AS ErrorState  
            ,ERROR_PROCEDURE() AS ErrorProcedure  
            ,ERROR_LINE() AS ErrorLine  
            ,ERROR_MESSAGE() AS ErrorMessage;  

			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetAllIntegrationPartOffline' 
               , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PartNumber, '') + ''',
														
														@Parameter5 = ' + ISNULL(@IntegrationPortalId,'') + ', 
											
														@Parameter17 = ' + ISNULL(@MasterCompanyId,'') + ''

              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END