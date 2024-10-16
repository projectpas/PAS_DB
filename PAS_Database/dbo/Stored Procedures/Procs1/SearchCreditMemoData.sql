﻿/*********************             
 ** File:   SearchCreditMemoData           
 ** Author:  Moin  
 ** Description: Get Credit Memo Filter Data  
 ** Purpose:           
 ** Date:   18-april-2022          
            
    
 **********************             
  ** Change History             
 **********************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    04/18/2022   Moin Bloch        Created  
	2    04/18/2022   Happy             Updated 
	3    09/04/2023   AMIT GHEDIYA      Updated to get from standaloneCM.
	4    09/15/2023   AMIT GHEDIYA      Updated to Cast.
	5    04/04/2024   Devendra Shekh    added vendorid to select
	6    04/10/2024   HEMANT            Updated Status Id 
	7    06/25/2024   Moin Bloch        Updated Multiple Reson
   
 -- exec SearchCreditMemoData 10,1,'CreatedDate',-1,'',1,null,null,'',null,null,null,null,null,null,null,null,null,null,null,null,null,null,2,'',15,0,1   
**********************/   
  
CREATE   PROCEDURE [dbo].[SearchCreditMemoData]  
	@PageSize int=NULL,  
	@PageNumber int=NULL,  
	@SortColumn varchar(50)=NULL,   
	@SortOrder int=NULL,  
	@GlobalFilter varchar(50)=NULL,  
	@StatusID int=NULL,  
	@CreditMemoNumber varchar(50)=NULL,  
	@IssueDate datetime=NULL,  
	@Status varchar(50)=NULL,  
	@Reason varchar(50)=NULL,  
	@RMANumber varchar(50)=NULL,  
	@WONum varchar(50)=NULL,  
	@CustomerName varchar(50)=NULL,  
	@PartNumber varchar(50)=NULL,  
	@PartDescription varchar(250)=NULL,  
	@ReferenceNo varchar(50)=NULL,  
	@Qty varchar(50),  
	@UnitPrice varchar(50),  
	@Amount varchar(50),  
	@RequestedBy varchar(50)=NULL,  
	@LastMSLevel varchar(50)=NULL,  
	@Memo varchar(50)=NULL,  
	@ReturnDate datetime=NULL,  
	@MasterCompanyId int=NULL,  
	@ViewType varchar(10)=NULL,  
	@EmployeeId bigint=1,  
	@IsDeleted bit=NULL,  
	@IsActive bit=NULL,  
	@ManufacturerName varchar(50)= NULL  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY    
   DECLARE @RecordFrom int;   
   DECLARE @ModuleID varchar(500) ='61'     
   Declare @Count Int;    
   SET @RecordFrom = (@PageNumber - 1) * @PageSize;  
  
   if(@GlobalFilter IS NULL)  
   begin  
   set @GlobalFilter='';  
   end  
  
   IF @SortColumn IS NULL    
   Begin    
    Set @SortColumn = UPPER('CreatedDate')    
   End     
   Else    
   Begin     
    Set @SortColumn = UPPER(@SortColumn)    
   End  
   IF (@StatusID=11 AND @Status='All')  
   BEGIN     
   SET @Status = ''  
   END  
   IF (@StatusID=11 OR @StatusID=0)  
   BEGIN  
   SET @StatusID = NULL     
      END             
     ;WITH Result AS(SELECT DISTINCT CM.[CreditMemoHeaderId]  
                           ,CM.[CreditMemoNumber]  
                           ,CM.[RMAHeaderId]  
                           ,CM.[RMANumber]  
                           ,CM.[InvoiceId]  
                           ,CM.[InvoiceNumber]  
                           ,ISNULL(CM.[InvoiceDate],'') AS InvoiceDate  
                           ,CM.[StatusId]  
                           ,CM.[Status]  
                           ,CM.[CustomerId]  
                           ,CM.[CustomerName]  
                           ,CM.[CustomerCode]  
                           ,CM.[CustomerContactId]  
                           ,CM.[CustomerContact]  
                           ,CM.[CustomerContactPhone]  
                           ,CM.[IsWarranty]  
                           ,CM.[IsAccepted]  
                           ,CM.[ReasonId]            
                           ,CM.[DeniedMemo]  
                           ,CM.[RequestedById]  
                           ,CM.[RequestedBy]  
                           ,CM.[ApproverId]  
                           ,CM.[ApprovedBy]  
                           ,CM.[WONum]  
                           ,CM.[WorkOrderId]  
                           ,CM.[Originalwosonum]  
                           ,CM.[Memo]  
                           ,CM.[Notes]  
                           ,CM.[ManagementStructureId]  
                           ,CM.[IsEnforce]  
                           ,CM.[MasterCompanyId]  
                           ,CM.[CreatedBy]  
                           ,CM.[UpdatedBy]  
                           ,CM.[CreatedDate]  
                           ,CM.[UpdatedDate]  
                           ,CM.[IsActive]  
                           ,CM.[IsDeleted]  
                        ,MS.[LastMSLevel]  
						,MS.[AllMSlevels]        
                  ,0 as [Qty]     
                  ,0 as [Amount]  
                  ,CM.[CreatedDate] AS IssueDate  
                  ,CM.[ReturnDate]
				  ,CM.IsStandAloneCM
				  ,ISNULL(VR.VendorId, 0) AS VendorId
        FROM dbo.CreditMemo CM WITH (NOLOCK)           
            --LEFT JOIN dbo.CreditMemoDetails CD WITH (NOLOCK)  ON CD.CreditMemoHeaderId = CM.CreditMemoHeaderId    
           INNER JOIN dbo.[RMACreditMemoManagementStructureDetails] MS WITH (NOLOCK) ON  MS.ReferenceID = CM.CreditMemoHeaderId AND MS.ModuleID = @ModuleID  
              INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON CM.ManagementStructureId = RMS.EntityStructureId  
              INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId   
              LEFT JOIN dbo.Vendor VR WITH (NOLOCK) ON VR.RelatedCustomerId = CM.CustomerId
  
        WHERE ((CM.MasterCompanyId = @MasterCompanyId) AND (CM.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR CM.StatusId = @StatusID))    
   ),  
   PartCTE AS(    
    Select CRD.CreditMemoHeaderId,(Case When COUNT(CRD.CreditMemoHeaderId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PartNumber',    
    A.PartNumber [PartNumberType] from dbo.CreditMemo CRH WITH (NOLOCK)   
    LEFT JOIN dbo.CreditMemoDetails CRD WITH (NOLOCK) ON CRH.CreditMemoHeaderId =CRD.CreditMemoHeaderId  
    OUTER APPLY(    
     SELECT     
     STUFF((SELECT CASE WHEN LEN(I.partnumber) >0 THEN ',' ELSE '' END + I.partnumber    
      FROM dbo.CreditMemoDetails S WITH (NOLOCK)    
      Left Join dbo.ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId    
      Where S.CreditMemoHeaderId = CRD.CreditMemoHeaderId    
      AND S.IsActive = 1 AND S.IsDeleted = 0    
      FOR XML PATH('')), 1, 1, '') PartNumber    
    ) A    
    WHERE CRH.MasterCompanyId=@MasterCompanyId AND ISNULL(CRH.IsDeleted,0)=0  
    Group By CRD.CreditMemoHeaderId, A.PartNumber    
    ),  
    PartDescCTE AS(    
    Select CRD.CreditMemoHeaderId,(CASE WHEN COUNT(CRD.CreditMemoHeaderId) > 1 Then 'Multiple' ELSE A.PartDescription END)  AS 'PartDescription',    
    A.PartDescription [PartDescriptionType] FROM dbo.CreditMemo CRH WITH (NOLOCK)   
    LEFT JOIN dbo.CreditMemoDetails CRD WITH (NOLOCK) ON CRH.CreditMemoHeaderId = CRD.CreditMemoHeaderId  
    OUTER APPLY(    
     SELECT     
     STUFF((SELECT CASE WHEN LEN(I.PartDescription) >0 then ',' ELSE '' END + I.PartDescription    
      FROM dbo.CreditMemoDetails S WITH (NOLOCK)    
      LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId    
      Where S.CreditMemoHeaderId = CRD.CreditMemoHeaderId    
      AND S.IsActive = 1 AND S.IsDeleted = 0    
      FOR XML PATH('')), 1, 1, '') PartDescription    
    ) A    
    WHERE CRH.MasterCompanyId=@MasterCompanyId AND ISNULL(CRH.IsDeleted,0)=0  
    Group By CRD.CreditMemoHeaderId, A.PartDescription    
    ),  
  
    ManufacturerNameCTE AS(    
    Select CRD.CreditMemoHeaderId,(CASE WHEN COUNT(CRD.CreditMemoHeaderId) > 1 Then 'Multiple' ELSE A.ManufacturerName END)  AS 'ManufacturerName',    
    A.ManufacturerName [ManufacturerNameType] FROM dbo.CreditMemo CRH WITH (NOLOCK)   
    LEFT JOIN dbo.CreditMemoDetails CRD WITH (NOLOCK) ON CRH.CreditMemoHeaderId = CRD.CreditMemoHeaderId  
    OUTER APPLY(    
     SELECT     
     STUFF((SELECT CASE WHEN LEN(I.ManufacturerName) > 0 THEN ',' ELSE '' END + I.ManufacturerName    
      FROM dbo.CreditMemoDetails S WITH (NOLOCK)    
      LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) ON S.ItemMasterId=I.ItemMasterId    
      Where S.CreditMemoHeaderId = CRD.CreditMemoHeaderId    
      AND S.IsActive = 1 AND S.IsDeleted = 0    
      FOR XML PATH('')), 1, 1, '') ManufacturerName    
    ) A    
    WHERE CRH.MasterCompanyId=@MasterCompanyId AND ISNULL(CRH.IsDeleted,0)=0  
    Group By CRD.CreditMemoHeaderId, A.ManufacturerName    
    ),  
      
   CMReasonCTE AS(    
    SELECT 
	CASE WHEN CRH.IsStandAloneCM = 1 THEN SCRD.CreditMemoHeaderId ELSE CRD.CreditMemoHeaderId END CreditMemoHeaderId,
	CASE WHEN CRH.IsStandAloneCM = 1 THEN 
		(CASE WHEN COUNT(SCRD.CreditMemoHeaderId) > 1 Then 'Multiple' ELSE B.Reason End)
		ELSE 
		(CASE WHEN COUNT(CRD.CreditMemoHeaderId) > 1 Then 'Multiple' ELSE A.Reason End)
	END	AS 'Reason',  
	CASE WHEN CRH.IsStandAloneCM = 1 THEN B.Reason ELSE A.Reason END AS [ReasonType]
	
	FROM dbo.CreditMemo CRH WITH (NOLOCK)   
    LEFT JOIN dbo.CreditMemoDetails CRD WITH (NOLOCK) ON CRH.CreditMemoHeaderId = CRD.CreditMemoHeaderId  
	LEFT JOIN dbo.StandAloneCreditMemoDetails SCRD WITH (NOLOCK) ON CRH.CreditMemoHeaderId = SCRD.CreditMemoHeaderId 
    OUTER APPLY(    
     SELECT     
     STUFF((SELECT CASE WHEN LEN(S.Reason) > 0 THEN ',' ELSE '' END + S.Reason    
      FROM dbo.CreditMemoDetails S WITH (NOLOCK)         
      Where S.CreditMemoHeaderId = CRD.CreditMemoHeaderId AND ISNULL(CRH.IsStandAloneCM,0) = 0
      AND S.IsActive = 1 AND S.IsDeleted = 0    
      FOR XML PATH('')), 1, 1, '') Reason    
    ) A  
	OUTER APPLY(    
     SELECT     
     STUFF((SELECT CASE WHEN LEN(S.Reason) > 0 THEN ',' ELSE '' END + S.Reason    
      FROM dbo.StandAloneCreditMemoDetails S WITH (NOLOCK)         
      Where S.CreditMemoHeaderId = SCRD.CreditMemoHeaderId AND CRH.IsStandAloneCM = 1
      AND S.IsActive = 1 AND S.IsDeleted = 0    
      FOR XML PATH('')), 1, 1, '') Reason    
    ) B  
	 WHERE CRH.MasterCompanyId=@MasterCompanyId AND ISNULL(CRH.IsDeleted,0) = 0 GROUP BY CRD.CreditMemoHeaderId, SCRD.CreditMemoHeaderId,CRH.IsStandAloneCM,A.Reason,B.Reason        
    ),  

   CMUnitPriceCTE AS(    
    Select CRD.CreditMemoHeaderId,(CASE WHEN COUNT(CRD.CreditMemoHeaderId) > 1 Then 'Multiple' ELSE A.UnitPrice End)  as 'UnitPrice',    
    A.UnitPrice [UnitPriceType] FROM dbo.CreditMemo CRH WITH (NOLOCK)   
    LEFT JOIN dbo.CreditMemoDetails CRD WITH (NOLOCK) ON CRH.CreditMemoHeaderId =CRD.CreditMemoHeaderId  
    OUTER APPLY(    
     SELECT     
     STUFF((SELECT CASE WHEN LEN(CAST(S.UnitPrice AS NVARCHAR(10))) > 0 THEN ',' ELSE '' END + CAST(S.UnitPrice AS NVARCHAR(10))   
      FROM dbo.CreditMemoDetails S WITH (NOLOCK)    
      Where S.CreditMemoHeaderId = CRD.CreditMemoHeaderId    
      AND S.IsActive = 1 AND S.IsDeleted = 0    
      FOR XML PATH('')), 1, 1, '') UnitPrice    
    ) A    
    WHERE CRH.MasterCompanyId=@MasterCompanyId AND isnull(CRH.IsDeleted,0) = 0 GROUP BY CRD.CreditMemoHeaderId, A.UnitPrice    
    ),       
     Results AS( SELECT DISTINCT M.[CreditMemoHeaderId],M.[CreditMemoNumber],M.[RMAHeaderId],M.[RMANumber],M.[InvoiceId],M.[InvoiceNumber],  
           ISNULL(M.[InvoiceDate],'') AS InvoiceDate,
		   M.[StatusId],M.[Status],M.[CustomerId],M.[CustomerName],M.[CustomerCode],M.[CustomerContactId],  
           M.[CustomerContact],M.[CustomerContactPhone],M.[IsWarranty],M.[IsAccepted],M.[ReasonId],M.[DeniedMemo],  
           M.[RequestedById],M.[RequestedBy],M.[ApproverId],M.[ApprovedBy],M.[WONum],M.[WorkOrderId],M.[Originalwosonum],  
           M.[Memo],M.[Notes],M.[ManagementStructureId],M.[IsEnforce],M.[MasterCompanyId],M.[CreatedBy],M.[UpdatedBy],  
           M.[CreatedDate] ,M.[UpdatedDate],M.[IsActive],M.[IsDeleted],M.[LastMSLevel],M.[AllMSlevels],  
           CASE WHEN ABS(SUM(SACD.Qty)) > 0 THEN SUM(SACD.Qty) ELSE SUM(CD.Qty) END AS Qty,  
           CASE WHEN ABS(SUM(SACD.Amount)) > 0 THEN SUM(SACD.Amount) ELSE SUM(CD.Amount) END AS Amount,  
           M.IssueDate,  
           M.ReturnDate,  
           PT.PartNumber,PT.PartNumberType,  
           PD.PartDescription,PD.PartDescriptionType,  
           RC.Reason,RC.ReasonType,  
           CASE WHEN SUM(SACD.Rate) > 0 THEN CAST(SUM(SACD.Rate) AS VARCHAR(200)) ELSE CAST(UC.UnitPrice AS VARCHAR(200)) END AS UnitPrice,
		   UC.UnitPriceType,  
           CD.ReferenceNo,  
           CD.IsWorkOrder,  
           CD.[ReferenceId]  
           ,MF.ManufacturerName  
           ,MF.ManufacturerNameType,
		   M.IsStandAloneCM
		   ,M.VendorId
           FROM Result M     
     LEFT JOIN dbo.CreditMemoDetails CD WITH (NOLOCK)  ON CD.CreditMemoHeaderId = M.CreditMemoHeaderId
	 LEFT JOIN dbo.StandAloneCreditMemoDetails SACD WITH (NOLOCK)  ON SACD.CreditMemoHeaderId = M.CreditMemoHeaderId AND SACD.IsActive = 1
     LEFT JOIN PartCTE PT ON M.CreditMemoHeaderId = PT.CreditMemoHeaderId  
     LEFT JOIN PartDescCTE PD ON PD.CreditMemoHeaderId = M.CreditMemoHeaderId  
     LEFT JOIN CMReasonCTE RC ON RC.CreditMemoHeaderId = M.CreditMemoHeaderId       
     LEFT JOIN CMUnitPriceCTE UC ON UC.CreditMemoHeaderId =  M.CreditMemoHeaderId  
     LEFT JOIN ManufacturerNameCTE  MF ON MF.CreditMemoHeaderId = M.CreditMemoHeaderId  
     GROUP BY   
     M.[CreditMemoHeaderId],M.[CreditMemoNumber],M.[RMAHeaderId],M.[RMANumber],M.[InvoiceId],M.[InvoiceNumber],  
           ISNULL(M.[InvoiceDate],''),
		   M.[StatusId],M.[Status],M.[CustomerId],M.[CustomerName],M.[CustomerCode],M.[CustomerContactId],  
           M.[CustomerContact],M.[CustomerContactPhone],M.[IsWarranty],M.[IsAccepted],M.[ReasonId],M.[DeniedMemo],  
           M.[RequestedById],M.[RequestedBy],M.[ApproverId],M.[ApprovedBy],M.[WONum],M.[WorkOrderId],M.[Originalwosonum],  
           M.[Memo],M.[Notes],M.[ManagementStructureId],M.[IsEnforce],M.[MasterCompanyId],M.[CreatedBy],M.[UpdatedBy],  
           M.[CreatedDate] ,M.[UpdatedDate],M.[IsActive],M.[IsDeleted],M.[LastMSLevel],M.[AllMSlevels],      
           M.IssueDate,  
           M.ReturnDate,  
           PT.PartNumber,  
           PT.PartNumberType,  
           PD.PartDescription,  
           PD.PartDescriptionType,  
           RC.Reason,  
           RC.ReasonType,  
           UC.UnitPrice, 
           UC.UnitPriceType,  
           CD.ReferenceNo,  
           CD.IsWorkOrder,  
           CD.[ReferenceId],MF.ManufacturerName ,MF.ManufacturerNameType,M.IsStandAloneCM,M.VendorId
    ),ResultCount AS(SELECT COUNT(CreditMemoHeaderId) AS totalItems FROM Results)    
    SELECT * INTO #TempResult2 from  Results  
     WHERE ((@GlobalFilter <>'' AND (    
            (CreditMemoNumber like '%' +@GlobalFilter+'%') OR    
            ([Status] like '%' +@GlobalFilter+'%') OR    
            (Reason like '%' +@GlobalFilter+'%') OR   
            (RMANumber like '%' +@GlobalFilter+'%') OR   
            (WONum like '%' +@GlobalFilter+'%') OR   
            (CustomerName like '%' +@GlobalFilter+'%') OR   
            (ManufacturerName like '%' +@GlobalFilter+'%') OR   
            (PartNumber like '%'+@GlobalFilter+'%') OR    
            (PartDescription like '%' +@GlobalFilter+'%') OR   
            (ReferenceNo like '%' +@GlobalFilter+'%') OR    
            (RequestedBy like '%' +@GlobalFilter+'%') OR    
            (CAST(Qty AS NVARCHAR(200)) LIKE '%' +@GlobalFilter+'%') OR   
            (CAST(UnitPrice AS VARCHAR(200)) LIKE '%' +@GlobalFilter+'%') OR   
            (CAST(Amount AS NVARCHAR(200)) LIKE '%' +@GlobalFilter+'%') OR   
            (LastMSLevel like '%' +@GlobalFilter+'%') OR   
            (Memo like '%'+@GlobalFilter+'%')))    
            OR       
            (@GlobalFilter='' AND   
            (ISNULL(@CreditMemoNumber,'') ='' OR CreditMemoNumber like '%' + @CreditMemoNumber+'%') AND     
            (ISNULL(@IssueDate,'') ='' OR Cast(IssueDate as Date)=Cast(@IssueDate as date)) AND   
            (ISNULL(@Status,'') ='' OR [Status] like '%' + @Status+'%') AND    
            (ISNULL(@Reason,'') ='' OR Reason like '%' + @Reason+'%') AND   
            (ISNULL(@RMANumber,'') ='' OR RMANumber like '%' + @RMANumber+'%') AND    
            (ISNULL(@ManufacturerName,'') ='' OR ManufacturerName like '%' + @ManufacturerName+'%') AND    
            (ISNULL(@WONum,'') ='' OR WONum like '%' + @WONum+'%') AND    
            (ISNULL(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') AND    
            (ISNULL(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND    
            (ISNULL(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') AND    
            (ISNULL(@ReferenceNo,'') ='' OR ReferenceNo like '%' + @ReferenceNo +'%') AND    
            (ISNULL(@ReturnDate,'') ='' OR Cast(ReturnDate as Date)=Cast(@ReturnDate as date)) AND   
			(ISNULL(CAST(@Qty AS VARCHAR(200)),'') = '' OR CAST(Qty AS varchar(200)) Like '%' +  ISNULL(CAST(@Qty AS VARCHAR(200)),'') +'%') AND  
			(ISNULL(CAST(@UnitPrice AS VARCHAR(200)),'') = '' OR CAST(UnitPrice AS varchar(200)) Like '%' +  ISNULL(CAST(@UnitPrice AS VARCHAR(200)),'') +'%') AND  
            (ISNULL(CAST(@Amount AS VARCHAR(200)),'') = '' OR CAST(Amount AS varchar(200)) Like '%' +  ISNULL(CAST(@Amount AS VARCHAR(200)),'') +'%') AND   
            (ISNULL(@RequestedBy,'') ='' OR RequestedBy like '%' + @RequestedBy+'%') AND   
            (ISNULL(@LastMSLevel,'') ='' OR LastMSLevel like '%' + @LastMSLevel+'%') AND  
            (ISNULL(@Memo,'') ='' OR Memo like '%' + @Memo+'%')))   
    
      SELECT @Count = COUNT(CreditMemoHeaderId) from #TempResult2      
    
      SELECT *, @Count As NumberOfItems FROM #TempResult2 ORDER BY      
  
            CASE WHEN (@SortOrder=1 and @SortColumn='CREDITMEMONUMBER')  THEN CreditMemoNumber END ASC,    
            CASE WHEN (@SortOrder=1 and @SortColumn='ISSUEDATE')  THEN IssueDate END ASC,    
            CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,    
            CASE WHEN (@SortOrder=1 and @SortColumn='REASON')  THEN Reason END ASC,    
            CASE WHEN (@SortOrder=1 and @SortColumn='RMANUMBER')  THEN RMANumber END ASC,    
            CASE WHEN (@SortOrder=1 and @SortColumn='WONUM')  THEN WONum END ASC,  
            CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,    
            CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,    
            CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,    
            CASE WHEN (@SortOrder=1 and @SortColumn='ORIGINALWOSONUM')  THEN Originalwosonum END ASC,    
            CASE WHEN (@SortOrder=1 and @SortColumn='RETURNDATE')  THEN ReturnDate END ASC,    
            CASE WHEN (@SortOrder=1 and @SortColumn='QTY')  THEN Qty END ASC,    
            CASE WHEN (@SortOrder=1 and @SortColumn='UNITPRICE')  THEN UnitPrice END ASC,    
            CASE WHEN (@SortOrder=1 and @SortColumn='AMOUNT')  THEN Amount END ASC,    
            CASE WHEN (@SortOrder=1 and @SortColumn='REQUESTEDBY')  THEN RequestedBy END ASC,    
            CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,   
            CASE WHEN (@SortOrder=1 and @SortColumn='MEMO')  THEN Memo END ASC,    
            CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,    
            CASE WHEN (@SortOrder=1 and @SortColumn='ReferenceNo')  THEN ReferenceNo END ASC,   
            CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,  
  
            CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END Desc,    
            CASE WHEN (@SortOrder=-1 and @SortColumn='CREDITMEMONUMBER')  THEN CreditMemoNumber END DESC,    
            CASE WHEN (@SortOrder=-1 and @SortColumn='ISSUEDATE')  THEN IssueDate END DESC,    
            CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END DESC,    
            CASE WHEN (@SortOrder=-1 and @SortColumn='REASON')  THEN Reason END DESC,    
            CASE WHEN (@SortOrder=-1 and @SortColumn='RMANUMBER')  THEN RMANumber END DESC,    
            CASE WHEN (@SortOrder=-1 and @SortColumn='WONUM')  THEN WONum END DESC,  
            CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END DESC,    
            CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END DESC,    
            CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,    
            CASE WHEN (@SortOrder=-1 and @SortColumn='ORIGINALWOSONUM')  THEN Originalwosonum END DESC,    
            CASE WHEN (@SortOrder=-1 and @SortColumn='RETURNDATE')  THEN ReturnDate END DESC,    
            CASE WHEN (@SortOrder=-1 and @SortColumn='QTY')  THEN Qty END DESC,    
            CASE WHEN (@SortOrder=-1 and @SortColumn='UNITPRICE')  THEN UnitPrice END DESC,    
            CASE WHEN (@SortOrder=-1 and @SortColumn='AMOUNT')  THEN Amount END DESC,    
            CASE WHEN (@SortOrder=-1 and @SortColumn='REQUESTEDBY')  THEN RequestedBy END DESC,    
            CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC,   
            CASE WHEN (@SortOrder=-1 and @SortColumn='MEMO')  THEN Memo END DESC,  
            CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
            CASE WHEN (@SortOrder=-1 and @SortColumn='ReferenceNo')  THEN ReferenceNo END DESC  
                   
            OFFSET @RecordFrom ROWS     
            FETCH NEXT @PageSize ROWS ONLY            
  
 END TRY      
 BEGIN CATCH  
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'SearchCreditMemoData'   
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))  
      + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100))   
      + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))  
      + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))  
      + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))  
      + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))  
      + '@Parameter7 = ''' + CAST(ISNULL(@RMANumber, '') AS varchar(100))        
      + '@Parameter8 = ''' + CAST(ISNULL(@ReturnDate, '') AS varchar(100))  
      + '@Parameter9 = ''' + CAST(ISNULL(@CustomerName, '') AS varchar(100))  
      + '@Parameter10 = ''' + CAST(ISNULL(@PartNumber, '') AS varchar(100))  
      + '@Parameter11 = ''' + CAST(ISNULL(@PartDescription , '') AS varchar(100))       
      + '@Parameter12 = ''' + CAST(ISNULL(@Qty , '') AS varchar(100))  
      + '@Parameter13 = ''' + CAST(ISNULL(@UnitPrice , '') AS varchar(100))  
      + '@Parameter14 = ''' + CAST(ISNULL(@Amount , '') AS varchar(100))        
      + '@Parameter15 = ''' + CAST(ISNULL(@LastMSLevel , '') AS varchar(100))  
      + '@Parameter16 = ''' + CAST(ISNULL(@MasterCompanyId  , '') AS varchar(100))  
      + '@Parameter17 = ''' + CAST(ISNULL(@ViewType  , '') AS varchar(100))  
      + '@Parameter18 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100))   
      + '@Parameter19 = ''' + CAST(ISNULL(@IsDeleted  , '') AS varchar(100))  
      + '@Parameter20 = ''' + CAST(ISNULL(@Memo, '') AS varchar(100))   
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
 END CATCH  
END