
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.USP_AddUpdateTravelerSetupHeader   (source: PAS_DB/dbo/Stored Procedures/Procs2/USP_AddUpdateTravelerSetupHeader.sql)
-- ---------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------  
  
/*************************************************************             
 ** File:   [USP_AddUpdateTravelerSetupHeader]             
 ** Author:   Subhash Saliya  
 ** Description: This stored procedure is used To Add/Update WO Traveler Record    
 ** Purpose:           
 ** Date:   12/22/2023          
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    12/22/2023   Subhash Saliya  Created
	2    05/22/2023   Satish Gohil    Update Code prefix function
	3    01/09/2025   Moin Bloch      Changed [WorkScope] Discription to [WorkScopeCode]
	4    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
       
-- EXEC [USP_AddUpdateTravelerSetupHeader] 44  
**************************************************************/  
  
CREATE     PROCEDURE [dbo].[USP_AddUpdateTravelerSetupHeader]  
 @WorkScopeId bigint,    
 @MasterCompanyId bigint,    
 @CreatedBy varchar(100),  
 @Traveler_SetupId bigint ,  
 @ItemMasterId bigint = null,  
 @IsVersionIncrease bit=0,  
 @Old_Traveler_SetupId bigint=0 ,  
 @isCopyTraveler bit=0  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    
				DECLARE @TravelerId varchar(100) =''  
                DECLARE @Version varchar(100) =''  
                DECLARE @WorkScope varchar(100) =''  
				DECLARE @PartNumber varchar(100) =''  
				DECLARE @currentNo AS BIGINT = 0;  
				DECLARE @TravelerVersio_currentNo AS BIGINT = 0;  
				DECLARE @CodeTypeTravelerId AS BIGINT = 76;  
				DECLARE @TravelerVersionId AS BIGINT = 77;  
				DECLARE @Traveler_SetupIdNew AS BIGINT = 0;  
                  
                SELECT TOP 1 @WorkScope=[WorkScopeCode] FROM [dbo].[WorkScope] WITH(NOLOCK) WHERE WorkScopeId=@WorkScopeId   
                SELECT TOP 1 @PartNumber=partnumber from [dbo].[ItemMaster] WITH(NOLOCK) WHERE  ItemMasterId=@ItemMasterId   
                 
  
                 AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0
                 IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL  
				BEGIN  
					DROP TABLE #tmpCodePrefixes  
				END  
            
			  CREATE TABLE #tmpCodePrefixes  
			  (  
				ID BIGINT NOT NULL IDENTITY,   
				CodePrefixId BIGINT NULL,  
				CodeTypeId BIGINT NULL,  
				CurrentNumber BIGINT NULL,  
				CodePrefix VARCHAR(50) NULL,  
				CodeSufix VARCHAR(50) NULL,  
				StartsFrom BIGINT NULL,  
			  )  
			 IF(@isCopyTraveler = 1)  
			 BEGIN  
				 IF(ISNULL(@isCopyTraveler,0) = 1)  
				  BEGIN  
					SET @IsVersionIncrease=0  
         
					   SELECT TOP 1 @CodeTypeTravelerId=CodeTypeId FROM [dbo].[CodeTypes] WITH(NOLOCK)  WHERE CodeType='TravelerId'  
					   SELECT TOP 1 @TravelerVersionId=CodeTypeId FROM [dbo].[CodeTypes] WITH(NOLOCK)  WHERE CodeType='TravelerVersion'  
                 
					  INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom)   
					  SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom   
					  FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId  
					  WHERE CT.CodeTypeId IN (@TravelerVersionId,@CodeTypeTravelerId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;  
            
				  IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeTravelerId))  
				  BEGIN   
  
        IF(@IsVersionIncrease =1)  
        BEGIN  
            SELECT @TravelerId = TravelerId  FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE Traveler_SetupId = @Old_Traveler_SetupId  
        END  
        ELSE  
        BEGIN  
            SELECT @currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1   
             ELSE CAST(StartsFrom AS BIGINT) + 1 END   
                FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeTravelerId  
            
                SET @TravelerId = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeTravelerId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeTravelerId)))  
				UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeTravelerId AND MasterCompanyId = @MasterCompanyId   
        END   
        END  
        ELSE   
        BEGIN  
			ROLLBACK TRAN;  
        END    
        IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @TravelerVersionId))  
        BEGIN   
       
        IF(@IsVersionIncrease =1)  
        BEGIN  
            SELECT @TravelerVersio_currentNo = CASE WHEN CurrentNummber > 0 THEN CAST(CurrentNummber AS BIGINT) + 1   
             ELSE CurrentNummber + 1 END   
                   FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE Traveler_SetupId = @Old_Traveler_SetupId  
        END  
        ELSE  
        BEGIN  
            SET @TravelerVersio_currentNo=1  
        END  
           SET @Version = (SELECT * FROM dbo.udfGenerateCodeNumber(@TravelerVersio_currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @TravelerVersionId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @TravelerVersionId))) 
 
          END  
          ELSE   
          BEGIN  
           ROLLBACK TRAN;  
          END  
  
         INSERT INTO [dbo].[Traveler_Setup]  
                                ([TravelerId]  
                                ,[WorkScopeId]  
                                ,[WorkScope]  
                                ,[Version]  
								,[ItemMasterId]  
								,[PartNumber]
                                ,[MasterCompanyId]  
                                ,[CreatedBy]  
                                ,[UpdatedBy]  
                                ,[CreatedDate]  
                                ,[UpdatedDate]  
                                ,[IsActive]  
                                ,[IsDeleted]  
								,[IsVersionIncrease]  
								,CurrentNummber)  
                          VALUES  
                                (@TravelerId  
                                ,@WorkScopeId  
                                ,@WorkScope  
                                ,@Version  
								,@ItemMasterId  
								,@PartNumber  
                                ,@MasterCompanyId  
                                ,@CreatedBy  
                                ,@CreatedBy  
                                ,GETUTCDATE()  
                                ,GETUTCDATE()  
                                ,1  
                                ,0  
								,0  
								,@TravelerVersio_currentNo)  
  
        SELECT @Traveler_SetupIdNew =SCOPE_IDENTITY()   
  
        select   @Traveler_SetupIdNew as Traveler_SetupId  
  
          INSERT INTO [dbo].[Traveler_Setup_Task]  
                  ([Traveler_SetupId]  
                  ,[TaskId]  
                  ,[TaskName]  
                  ,[Notes]  
                  ,[Sequence]  
                  ,[MasterCompanyId]  
                  ,[CreatedBy]  
                  ,[UpdatedBy]  
                  ,[CreatedDate]  
                  ,[UpdatedDate]  
                  ,[IsActive]  
                  ,[IsDeleted]  
      ,IsVersionIncrease  
      )  
            Select  
                  @Traveler_SetupIdNew  
                  ,TaskId  
                  ,TaskName  
                  ,Notes  
                  ,Sequence  
                  ,@MasterCompanyId  
                  ,@CreatedBy  
                  ,@CreatedBy  
                  ,GETUTCDATE()  
                  ,GETUTCDATE()  
                  ,1  
                  ,0,0  from Traveler_Setup_Task where Traveler_SetupId=@Traveler_SetupId and IsDeleted=0  
  
  
     UPDATE dbo.CodePrefixes SET CurrentNummber = @TravelerVersio_currentNo WHERE CodeTypeId = @TravelerVersionId AND MasterCompanyId = @MasterCompanyId    
              END  
	 END  
	 ELSE  
	 BEGIN  
             IF(ISNULL(@Traveler_SetupId,0) = 0)  
             BEGIN  
         
			   SELECT TOP 1 @CodeTypeTravelerId=CodeTypeId FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE CodeType='TravelerId'  
			   SELECT TOP 1 @TravelerVersionId=CodeTypeId FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE CodeType='TravelerVersion'  
                             
			  INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom)   
			  SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom   
			  FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId  
			  WHERE CT.CodeTypeId IN (@TravelerVersionId,@CodeTypeTravelerId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;  
            
            IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeTravelerId))  
            BEGIN   
  
        IF(@IsVersionIncrease =1)  
        BEGIN  
            SELECT @TravelerId = TravelerId  FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE Traveler_SetupId = @Old_Traveler_SetupId  
        END  
        ELSE  
        BEGIN  
            SELECT @currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1   
             ELSE CAST(StartsFrom AS BIGINT) + 1 END   
                FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeTravelerId  
            
                SET @TravelerId = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeTravelerId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeTravelerId)))  
			
			UPDATE dbo.CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeTravelerId AND MasterCompanyId = @MasterCompanyId   
        END   
        END  
        ELSE   
        BEGIN  
          ROLLBACK TRAN;  
        END 
        IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @TravelerVersionId))  
        BEGIN   
        IF(@IsVersionIncrease =1)  
        BEGIN  
            SELECT @TravelerVersio_currentNo = CASE WHEN CurrentNummber > 0 THEN CAST(CurrentNummber AS BIGINT) + 1   
             ELSE CurrentNummber + 1 END   
                   FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE Traveler_SetupId = @Old_Traveler_SetupId  
        END  
        ELSE  
        BEGIN  
            SET @TravelerVersio_currentNo=1  
        END  
			SET @Version = (SELECT * FROM dbo.udfGenerateCodeNumber(@TravelerVersio_currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @TravelerVersionId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @TravelerVersionId))) 
 
          END  
          ELSE   
          BEGIN  
           ROLLBACK TRAN;  
          END  
  
         INSERT INTO [dbo].[Traveler_Setup]  
                                ([TravelerId]  
                                ,[WorkScopeId]  
                                ,[WorkScope]  
                                ,[Version]  
								,[ItemMasterId]  
								,[PartNumber]  
                                ,[MasterCompanyId]  
                                ,[CreatedBy]  
                                ,[UpdatedBy]  
                                ,[CreatedDate]  
                                ,[UpdatedDate]  
                                ,[IsActive]  
                                ,[IsDeleted]  
								,[IsVersionIncrease]  
								,CurrentNummber)  
                          VALUES  
                                (@TravelerId  
                                ,@WorkScopeId  
                                ,@WorkScope  
                                ,@Version  
								,@ItemMasterId  
								,@PartNumber  
                                ,@MasterCompanyId  
                                ,@CreatedBy  
                                ,@CreatedBy  
                                ,GETUTCDATE()  
                                ,GETUTCDATE()  
                                ,1  
                                ,0  
        ,0  
        ,@TravelerVersio_currentNo)  
  
        SELECT @@IDENTITY AS Traveler_SetupId    
  
        UPDATE [dbo].[CodePrefixes] SET CurrentNummber = @TravelerVersio_currentNo WHERE CodeTypeId = @TravelerVersionId AND MasterCompanyId = @MasterCompanyId    
              END  
    ELSE  
    BEGIN  
  
      UPDATE [dbo].[Traveler_Setup] SET ItemMasterId=@ItemMasterId,PartNumber=@PartNumber WHERE Traveler_SetupId=@Traveler_SetupId  
     SELECT @Traveler_SetupId AS Traveler_SetupId  
    END  
  END  
  IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL  
  BEGIN  
	DROP TABLE #tmpCodePrefixes  
  END             
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    --PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_AddUpdateTravelerSetupHeader'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkScopeId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName         = @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END